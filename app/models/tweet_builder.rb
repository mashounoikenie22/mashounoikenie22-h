class TweetBuilder
  LIMIT = 140

  attr_reader :tweet

  def initialize(user, bitly = nil)
    @user   = user
    @tweet  = ''
    @parts  = []
    @bitly  = bitly
  end

  def build(out = @out)
    @tweet  = ''

    media(out.media.map(&:media))
    target(out.target)
    targets(out.targets.map(&:target))
    hashtag(out.hashtags.map(&:tag))
    trend(out.trends.map(&:trend))
    comment(out.comment)
    video(out.video.guid) if out.video.present?

    @tweet.strip
  end

  def target(value, build = true)
    return '' if value.nil?

    targets   = nil
    profiles  = nil
    retweets  = nil

    case value
      when 'FOLLOWER'
        if build
          @user.following_me.each { |follower| add_to_tweet(follower.screen_name, '@') }
        else
          profiles = @user.following_me.map { |twitter_follower| map_user_to_profile(twitter_follower) }
        end
      when 'FOLLOWED_BY_I_FOLLOW'
        if build
          @user.followed_by_i_follow.each { |tweep| add_to_tweet(tweep.screen_name, '@') }
        else
          profiles = @user.followed_by_i_follow.map { |twitter_follow_by_i_follow| map_user_to_profile(twitter_follow_by_i_follow) }
        end
      when 'I_FOLLOW'
        if build
          @user.i_follow.each { |followee| add_to_tweet(followee.screen_name, '@') }
        else
          profiles = @user.i_follow.map { |i_follow| map_user_to_profile(i_follow) }
        end
      when 'TWEOPLE', 'TWEOPLE_WEB_ONLY', 'TWEOPLE_ALL_SOURCES'
        profiles = @user.tweople(value == 'TWEOPLE_WEB_ONLY' || value == 'TWEOPLE').map { |tweep| map_user_to_profile(tweep) }
      when 'TODAYS_MENTIONS'      then targets  = @user.mentioned.map { |status| map_status_to_target(status) }
      when 'TODAYS_SHOUTOUTS'     then targets  = @user.shoutouts.map { |status| map_status_to_target(status) }
      when 'TODAYS_RTS'           then retweets = @user.retweets_of_me.map { |status| map_retweet_to_profile(status) }
      when 'CELEB_VERIFIED'       then profiles = @user.verified.map { |verified| map_user_to_profile(verified) }
      when 'BESTIES'              then profiles = @user.twitter_besties.map { |twitter_bestie| map_user_to_profile(twitter_bestie) }
      else ''
    end

    [targets, profiles, retweets]
  end

  def video(value)
    return '' if value == 'NONE' or value.nil? or @bitly.nil?
    add_to_tweet(@bitly.shortened_url) if @user.videos.find_by_guid(value).present? and @bitly.shorten
  end

  def targets(targets)
    options(targets)
  end

  def media(value)
    options(value)
  end

  def hashtag(tags)
    options(tags)
  end

  def trend(trends)
    options(trends)
  end

  def comment(value)
    option(value)
  end

  def option(value)
    return '' if value == 'NONE' or value.nil?
    part = URI.decode(value)
    if not @parts.include? (part)
      add_to_tweet(part)
      @parts << part
    end
    @tweet
  end

  def options(values, prepend = '')
    return '' if values.nil?
    values.each do |value|
      part = URI.decode(value)
      if not @parts.include? (part)
        add_to_tweet(part, prepend)
        @parts << part
      end
    end
    @tweet
  end

  def add_to_tweet(string, prepend = '')
    return (@tweet << prepend << string << ' ') if (@tweet.length + string.length + 1) <= TweetBuilder::LIMIT
    @tweet
  end

  protected
    def map_status_to_target(status)
      {:screen_name           => '@' << status.user.screen_name,
       :text                  => status.text,
       :created_at            => status.created_at,
       :source                => status.source,
       :profile_image_url     => status.user.profile_image_url,
       :status_id             => status.id}
    end

    def map_user_to_profile(user)
      {:profile_image_url   => user.profile_image_url,
       :screen_name         => '@' << user.screen_name,
       :description         => user.description,
       :location            => user.location,
       :url                 => user.url,
       :last_tweet_from     => (user.status.present? ? user.status.source : nil),
       :twitter_id          => user.id,
       :follow_request_sent => user.follow_request_sent?
       }
    end

    def map_retweet_to_profile(retweet)
      {:text      => retweet[:text],
       :status_id => retweet[:status_id],
       :users     => retweet[:users].map { |user| {:profile_image_url => user.profile_image_url,
                                                   :screen_name       => '@' << user.screen_name} }}
    end
end

