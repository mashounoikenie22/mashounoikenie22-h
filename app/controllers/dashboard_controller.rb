class DashboardController < ApplicationController
  layout 'dashboard'

  before_filter :current_tool
  before_filter :auth_required, :except => :video_playback
  before_filter :available_networks, :if => :signed_in?
  before_filter :load_hashtags, :only => [:blastout, :mashout, :shoutout]
  before_filter :load_tool, :only => [:videos, :update_video, :delete_video]

  # TODO: refactor into separate controllers

  def index
    @besties      = get_besties
    @videos       = get_videos
    @interactions = get_interactions
  end

  def tool
    case(params['tool-selection'])
      when dashboard_mashout_url then redirect_to dashboard_mashout_url
      when dashboard_blastout_url then redirect_to dashboard_blastout_url
      when dashboard_shoutout_url then redirect_to dashboard_shoutout_url
      # TODO: temporarily disabled
      # when dashboard_pickout_url then redirect_to dashboard_pickout_url
      when dashboard_signout_url then redirect_to dashboard_signout_url
      else redirect_to dashboard_url
    end
  end

  def targets
    @target                         = params['mashout-target']
    @tweople_target                 = @target == 'TWEOPLE' ? (params['mashout-tweople-source'] ? params['mashout-tweople-source'] : 'TWEOPLE_WEB_ONLY') : nil
    @targets, @profiles, @retweets  = TweetBuilder.new(current_user).target(@target != 'TWEOPLE' ? @target : (@tweople_target || @target), false)

    if @profiles and @target == 'I_FOLLOW'
      @profiles.each do |profile|
        profile.merge!(local_friend_id: current_user.friends.find_by_twitter_user_id(profile[:twitter_id]).id)
      end
    end

    if @retweets
      @retweets.each do |retweet|
        # Filter out users that we have replied to
        retweet[:users].delete_if do |user|
          current_user.outs
                      .joins(:retweet_targets)
                      .where(:out_retweet_targets => { :status_id => retweet[:status_id].to_s,
                                                       :target    => user[:screen_name] })
                      .any?
        end
      end
    end

    @targets                        = group_hash_by(@targets, :screen_name)

    render :partial => 'target'
  end

  def trends
    @trend_source   = params[:trend_source]
    @trend_region   = params[:trend_location]
    @trend_woeid    = params[:trend_region]

    @trend_region = nil if @trend_region == 'NONE'
    @trend_woeid  = nil if @trend_region == nil or @trend_woeid == 'NONE'

    @locations, @regions, @trends = Trend.trends(current_user, @trend_source, @trend_region, @trend_woeid)

    if @trend_source == 'Trendspottr'
      @topics   = Trend.trendspottr_popular_topics
      @searches = Trend.trendspottr_popular_searches
    end

    render :partial => 'trend'
  end

  def trendspottr_search
    @trend_location = params[:trend_location].downcase
    @trend_search = params[:trend_search]

    if not %w(twitter facebook).include?(@trend_location)
      @trend_location = 'all'
    end

    @trends = Trend.trendspottr(@trend_search, @trend_location).last
    render :partial => 'trendspottr_results'
  end

  def mashout
  end

  def create_mashout
    create_out(params.merge('mashout-type' => 'Mashout'))
    handle_out_creation(dashboard_mashout_path)
  end

  def create_shoutout
    create_out(params.merge('mashout-type' => 'Shoutout'))
    handle_out_creation(dashboard_shoutout_path)
  end

  def create_blastout
    create_out(params.merge('mashout-type' => 'Blastout'))
    handle_out_creation(dashboard_blastout_path)
  end

  def blastout
    if (@guid = params['guid']).present?
      bitly = Bitly::Client.new(video_playback_url(@guid))

      bitly.shorten and (@video_url = bitly.shortened_url)

      video_name      = current_user.name << ' (' << @guid << ')'
      video           = Video.new(:guid => @guid, :name => video_name, :user => current_user, :bitly_uri => @video_url)
      flash[:errors]  = 'Sorry, but we are unable to save your video' if not video.save
    end

    @tool   = @current_tool
    @videos = get_videos
  end

  def shoutout
  end

  def pickout
  end

  def signout
    session[:user_id] = nil
    redirect_to root_url
  end

  def besties
    render_besties
  end

  def delete_bestie
    bestie = current_user.find_bestie(params['bestie'])

    if bestie.present?
      bestie.destroy
      @message = 'Removed ' << params['bestie'] << ' bestie'
    else
      @message = 'Bestie ' << params['bestie'] << ' not found'
    end

    render_besties
  end

  def create_bestie
    # TODO: bestie edit before save
    bestie_screen_name = params['bestie']
    bestie_screen_name.insert(0, '@') if bestie_screen_name[0] != '@'

    if current_user.besties.create(:screen_name => bestie_screen_name).save
      @message = 'Bestie ' << bestie_screen_name << ' created'
    else
      @message = 'Unable to create ' << bestie_screen_name
    end

    render_besties
  end

  def videos
    render_videos
  end

  def create_video
    name  = params['name']
    guid  = params['guid']
    video = Video.new(:guid => guid, :name => name, :user => current_user)

    if video.save
      message = nil
    else
      message = video.errors.full_messages.first
    end

    render :text => message
  end

  def update_video
    guid    = params['guid']
    name    = params['name']
    message = nil

    # TODO: refactor into video model
    if name.blank?
      message = 'Name is blank'
    elsif (video = current_user.videos.find_by_guid(guid)).present?
      video.name = name
      message = 'Unable to save' if not video.save
    end

    if message.present?
      render :text => message, :content_type => :text
    else
      render_videos
    end
  end

  def delete_video
    video = current_user.videos.find_by_guid(params['guid'])

    video.destroy if video.present?
    render_videos
  end

  def video_playback
    if (guid = params['guid']).present?
      @video = Video.find_by_guid(guid)
      render 'video_playback'
    else
      flash[:notice] = 'Sorry, but the video you requested was not found'
      redirect_to root_url
    end
  end

  def interactions
    @interactions = get_interactions
    render :partial => 'interactions'
  end

  def remove_networks
    if current_user.remove_networks(params)
      @message = 'Updated your connected networks!'
    else
      @message = current_user.errors.full_messages.to_sentence
    end

    available_networks

    render :partial => 'connected_networks'
  end

  protected
    def current_tool
      case params[:action].to_sym
        when :index then @current_tool = dashboard_url
        when :mashout then @current_tool = dashboard_mashout_url
        when :create_mashout then @current_tool = dashboard_mashout_url
        when :blastout then @current_tool = dashboard_blastout_url
        when :shoutout then @current_tool = dashboard_shoutout_url
        when :pickout then @current_tool = dashboard_pickout_url
        when :signout then @current_tool = dashboard_signout_url
        else @current_tool = dashboard_signout_url
      end
    end

    def available_networks
      @networks = {:twitter   => current_user.twitter.present?,
                   :facebook  => current_user.facebook.present?,
                   :youtube   => current_user.youtube.present?}
    end

    def create_out(params)
      begin
        @out          = params['out']
        new_out       = Out.new(params)
        new_out.user  = self.current_user
        new_out.video = Video.find_by_guid(params['mashout-video']) if params['mashout-video'].present?
        emitter       = TweetEmitter.new(self.current_user, new_out)

        emitter.validate!
        if emitter.errors.any?
          flash[:error] = emitter.errors.full_messages.to_sentence
          return false
        end

        @out = emitter.emit(new_out)

        if emitter.queued_emit?
          flash[:success] = 'Please wait while we process your OUT'
        else
          flash[:success] = 'Created your OUT!'
        end
      rescue Exception => ex
        flash[:error] = 'Unable to send your OUT.  ' << ex.message
      end

      flash[:success].present?
    end

    def render_besties
      @besties = get_besties
      render :partial => 'besties'
    end

    def get_besties
      current_user.twitter_besties.sort_by{|bestie| bestie.id}.paginate(:page => page, :per_page => per_page(10))
    end

    def get_videos
      current_user.videos.order('id DESC').paginate(:page => page, :per_page => per_page(4))
    end

    def render_videos
      @videos = get_videos
      render :partial => 'videos'
    end

    def get_interactions
      local_interactions = current_user.grouped_augmented_interactions(:group    => 'lower(target)',
                                                                       :page     => page,
                                                                       :per_page => per_page(8))

      # Make sure we return a paginated array so will_paginate doesn't fail
      return local_interactions if local_interactions.respond_to?(:total_pages)
      local_interactions.paginate(:page => page, :per_page => per_page(8))
    end

    def load_hashtags
      @hashtags = current_user.hashtags

      if @hashtags.empty?
        current_user.hashtags = User::DEFAULT_HASHTAGS.map{|hashtag| UserHashtag.new(:tag => hashtag) }
        @hashtags = current_user.hashtags
      end
    end

    def load_tool
      @tool = params['source']
    end

    def handle_out_creation(redirect_url)
      if request.xhr?
        if flash[:success].present?
          css_class = 'success'
          message = flash[:success]
        else
          css_class = 'error'
          message = flash[:error]
        end
        flash.discard

        render :partial => 'shared/flash_message', :locals => { :css_class => css_class, :message => message }
      else
        redirect_to redirect_url
      end
    end
end

