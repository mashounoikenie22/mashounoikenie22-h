class User < ActiveRecord::Base
  has_many :authorizations
  has_many :mentions
  has_many :replies
  has_many :besties, :class_name => 'Bestie'
  has_many :videos
  has_many :interactions
  has_many :outs
  has_many :targeted_mashouts,   :class_name => 'Out', :conditions => { :type => Mashout }
  has_many :top_trend_shoutouts, :class_name => 'Out', :conditions => { :type => Shoutout }
  has_many :video_blastouts,     :class_name => 'Out', :conditions => { :type => Blastout }
  has_many :friends, :dependent => :destroy
  has_many :followers
  has_many :hashtags, :class_name => 'UserHashtag'
  DEFAULT_HASHTAGS = %w(#Shoutout #ff #TFB #TeamFollowBack #F4F #FollowForFollow #Gratitude #S/O #ThankYou #Tweeps).freeze

  def self.create_from_hash!(hash)
    create(:name => hash['info']['name'])
  end

  def find_bestie(bestie)
    besties.where('lower(screen_name) = ?', bestie.downcase).first
  end

  def synchronize
    to_process_at = Time.now

    if self.friends.count < 1
      Resque.enqueue(TwitterFriendSynchronize, self.id)
    else
      to_process_at = 6.hours.from_now
      Resque.enqueue_at(to_process_at, TwitterFriendSynchronize, self.id)
    end

    if self.followers.count < 1
      Resque.enqueue(TwitterFollowerSynchronize, self.id)
    else
      to_process_at = 6.hours.from_now
      Resque.enqueue_at(to_process_at, TwitterFollowerSynchronize, self.id)
    end

    to_process_at
  end

  def twitter
    unless @twitter_client
      provider        = self.authorizations.find_by_provider('twitter')
      @twitter_client = Twitter::Client.new(:oauth_token => provider.token, :oauth_token_secret => provider.secret) rescue nil if provider.present?
    end

    @twitter_client
  end

  def remove_twitter
    remove_network('twitter')
    @twitter_client = nil
  end

  def remove_facebook
    remove_network('facebook')
    @facebook_client = nil
  end

  def remove_youtube
    remove_network('google')
    @youtube_client = nil
  end

  def remove_networks(params)
    has_twitter               = self.twitter.present?
    has_facebook              = self.facebook.present?
    wants_to_remove_twitter   = params['mashout-network-twitter'] == 'false'
    wants_to_remove_facebook  = params['mashout-network-facebook'] == 'false'

    if (has_twitter and not has_facebook and wants_to_remove_twitter) or (has_facebook and not has_twitter and wants_to_remove_facebook)
      errors[:base] = 'Must have at least Twitter or Facebook connected to use Mashoutable'
      return false
    end

    remove_twitter  if wants_to_remove_twitter
    remove_facebook if wants_to_remove_facebook
    remove_youtube  if params['mashout-network-youtube'] == 'false'

    true
  end

  def facebook
    unless @facebook_client
      provider          = self.authorizations.find_by_provider('facebook')
      @facebook_client  ||= FbGraph::User.me(provider.token) rescue nil if provider.present?
    end

    @facebook_client
  end

  def youtube
    unless @youtube_client
      provider = self.authorizations.find_by_provider('google')
      if provider.present?
        @youtube_client ||= YouTubeIt::OAuthClient.new(:consumer_key    => ENV['YOUTUBE_CONSUMER_KEY'],
                                                       :consumer_secret => ENV['YOUTUBE_CONSUMER_SECRET'],
                                                       :dev_key         => ENV['YOUTUBE_DEV_KEY'])
        @youtube_client.authorize_from_access(provider.token, provider.secret) if @youtube_client.present?
      end
    end

    @youtube_client
  end

  def tweople(web_only = true)
    tweople             = []
    follower_ids        = self.local_follower_ids
    friend_ids          = self.local_friend_ids
    public_screen_names = scrape_twitter_public_timeline(web_only)
    public_users        = public_screen_names.count > 0 ? twitter.users(public_screen_names) : []
    local_mentions      = self.mentions.find(:all, :select => :who).map { |mention| mention.who }

    public_users.each do |public_user|
      next if tweople.include?(public_user)
      next if local_mentions.include?(public_user.screen_name)
      next if friend_ids.include?(public_user.id)
      next if follower_ids.include?(public_user.id)

      tweople << public_user
    end

    tweople
  end

  def following_me
    # 1. get followers
    # 2. get friends
    # 3. remove friends from followers
    follower_ids      = self.local_follower_ids
    friend_ids        = self.local_friend_ids
    following_me_ids  = (follower_ids - friend_ids).shuffle!

    return [] if following_me_ids.count < 1

    begin
      twitter.users(following_me_ids.take(15))
    rescue Twitter::Error::NotFound
      []
    end
  end

  def followed_by_i_follow
    # 1. get followers
    # 2. get friends
    # 3. find from both where they are followers and friends (present on both lists)
    follower_ids      = self.local_follower_ids
    friend_ids        = self.local_friend_ids
    following_me_ids  = (follower_ids & friend_ids).shuffle!

    return [] if following_me_ids.count < 1

    begin
      twitter.users(following_me_ids.take(20))
    rescue Twitter::Error::NotFound
      []
    end
  end

  def i_follow
    # 1. get friends
    # 2. get followers
    # 3. remove followers from friends
    friend_ids    = self.local_friend_ids
    follower_ids  = self.local_follower_ids
    i_follow_ids  = (friend_ids - follower_ids).shuffle!

    return [] if i_follow_ids.count < 1

    begin
      twitter.users(i_follow_ids.take(15))
    rescue Twitter::Error::NotFound
      []
    end
  end

  def mentioned(date = Date.today)
    twitter_mentions  = twitter.mentions(:count => 200).select { |mention| mention.created_at.to_date == date }
    local_replies     = self.replies.find(:all, :select => :status_id).map { |mention| mention.status_id }

    twitter_mentions.reject do |twitter_mention|
      local_replies.include?(twitter_mention.id.to_s) or local_replies.include?(twitter_mention.in_reply_to_status_id.to_s)
    end
  end

  def shoutouts
    mentioned.select { |mention| mention.text =~ /#s\/o|#S\/O|#shoutouts|#SHOUTOUTS|#shoutout|#SHOUTOUT/ }
  end

  def retweets_of_me(date = Date.today)
    todays_retweets = twitter.retweets_of_me(:count => 200).select { |status| status.created_at.to_date == date }
    todays_retweets.map { |retweet| {:text => retweet.text, :status_id => retweet.id, :users => twitter.retweeters_of(retweet.id, :count => 10) } }
  end

  def verified
    tweep_ids = self.local_friend_ids + self.local_follower_ids

    return [] if tweep_ids.empty?

    verified_ids    = VerifiedTwitterUser.select(:user_id).map(&:user_id)
    user_verified   = tweep_ids & verified_ids

    return [] if user_verified.empty?

    begin
      twitter.users(user_verified.shuffle.take(20))
    rescue Twitter::Error::NotFound
      []
    end
  end

  def twitter_besties
    local_besties = self.besties

    return [] if local_besties.empty?

    begin
      self.twitter.users(local_besties.map { |bestie| bestie.screen_name.gsub('@', '') })
    rescue Twitter::Error::NotFound
      []
    end
  end

  def grouped_augmented_interactions(params)
    page                 = params.delete(:page) || 1
    per_page             = params.delete(:per_page) || 8
    interactions         = self.interactions.count(:all, params)

    return [] if not interactions.count > 0

    interactions = interactions.map { |target, count| { :screen_name => target, :count => count } }
    interactions.sort_by! { |interaction| interaction[:count].nil? ? 0 : interaction[:count] }
    interactions.reverse!
    interactions_on_page = interactions.paginate(:page => page, :per_page => per_page)

    twitter_users = self.twitter.users(interactions_on_page.map { |interaction| interaction[:screen_name].gsub('@', '') }) rescue []

    if twitter_users.any?
      interactions_on_page.each do |interaction|
        twitter_user = twitter_users.select { |user| "@#{user.screen_name.downcase}" == interaction[:screen_name].downcase }.first

        if twitter_user
          interaction[:screen_name]       = "@#{twitter_user.screen_name}"
          interaction[:profile_image_url] = twitter_user.profile_image_url
        end
      end
    end

    interactions_on_page
  end

  def twitter_ids(method, params = {}, limit = 1000)
    User.page_through_twitter_ids(twitter, method, params, limit)
  end

  def self.mashoutable_twitter
    Twitter::Client.new(:oauth_token => ENV['TWITTER_ACCESS_TOKEN'], :oauth_token_secret => ENV['TWITTER_ACCESS_SECRET'])
  end

  def self.page_through_twitter_ids(twitter_client, method, params = {}, limit = nil)
    ids     = []
    cursor  = -1

    while (results = twitter_client.send(method, params.merge({:cursor => cursor})))
      ids = ids + results['ids']
      return ids[0..limit] if limit.present? and ids.count >= limit
      break if results['next_cursor'] == 0
      cursor = results['next_cursor']
    end

    ids
  end

  def local_friend_ids
    self.friends.select(:twitter_user_id).map { |friend| friend.twitter_user_id }
  end

  def local_follower_ids
    self.followers.select(:twitter_user_id).map { |follower| follower.twitter_user_id }
  end

  protected
    def remove_network(network_name)
      provider = self.authorizations.find_by_provider(network_name)

      if network_name == Authorization::TWITTER
        Resque.remove_delayed(TwitterFriendSynchronize, self.id)
        Resque.remove_delayed(TwitterFollowerSynchronize, self.id)
      end

      provider.delete if provider.present?
    end

    def scrape_twitter_public_timeline(web_only = false)
      screen_names  = []
      doc           = Nokogiri::HTML(open('http://twitter.com/public_timeline'))

      doc.xpath('/html/body/div[3]/table/tbody/tr/td/div/div/ol/li/span[2]').each do |status|
        status_content  = status.xpath('span[@class="status-content"]')
        source          = status.xpath('span[@class="meta entry-meta"]/span')
        screen_name     = status_content.xpath('strong/a[@class="tweet-url screen-name"]')
        is_web_tweet    = source.text.casecmp('via web') == 0

        screen_names << screen_name.text if (not web_only) or (web_only and is_web_tweet)
      end

      screen_names
    end
end

