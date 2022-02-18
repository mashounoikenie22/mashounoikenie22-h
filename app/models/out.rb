class Out < ActiveRecord::Base
  belongs_to :user
  belongs_to :video
  has_many :hashtags,        :class_name => 'OutHashtag'
  has_many :trends,          :class_name => 'OutTrend'
  has_many :targets,         :class_name => 'OutTarget'
  has_many :replies,         :class_name => 'OutReply'
  has_many :media,           :class_name => 'OutMedia'
  has_many :retweet_targets, :class_name => 'OutRetweetTarget'
  has_many :out_errors
  validates_presence_of :user
  attr_accessible :hashtags_attributes, :trends_attributes,
                  :targets_attributes, :replies_attributes,
                  :media_attributes, :retweet_targets_attributes
  accepts_nested_attributes_for :hashtags, :trends, :targets, :replies, :media, :retweet_targets
  attr_accessible :content, :comment, :target,
                  :trend_source, :twitter, :facebook,
                  :youtube, :pending, :type

  scope :created_yesterday, lambda { where("created_at BETWEEN ? and ?", (Time.now.yesterday.midnight), Time.now.midnight) }

  def initialize(params = {})
    super map_incoming_params(params)
  end

  def successful?
    not out_errors.any?
  end

  private
    def map_incoming_params(params)
      atts = {:content      => uri_decode(params['out']),
              :comment      => uri_decode(params['mashout-comment']),
              :target       => uri_decode(params['mashout-target-selection']),
              :trend_source => uri_decode(params['trend-source']),
              :twitter      => params['mashout-network-twitter'] == 'true',
              :facebook     => params['mashout-network-facebook'] == 'true',
              :youtube      => params['mashout-network-youtube'] == 'true',
              :pending      => params['pending'],
              :type         => params['mashout-type']}

      atts[:hashtags_attributes]  = params['mashout-hashtag'].map {|tag| {:tag => uri_decode(tag), :out => self}} if params['mashout-hashtag'].present?
      atts[:trends_attributes]    = params['mashout-trend'].map {|trend| {:trend => uri_decode(trend), :out => self}} if params['mashout-trend'].present?
      atts[:trends_attributes]    = (atts[:trends_attributes] || []) + params['mashout-trendspottr-trends'].map { |trend| { :trend => uri_decode(trend), :out => self } } if params['mashout-trendspottr-trends'].present?
      atts[:replies_attributes]   = params['mashout-replies'].map {|reply| {:reply => uri_decode(reply), :out => self}} if params['mashout-replies'].present?
      atts[:targets_attributes]   = params['mashout-targets'].map {|target| {:target => uri_decode(target), :out => self}} if params['mashout-targets'].present?
      atts[:targets_attributes]   = (atts[:targets_attributes] || []) + params['mashout-trendspottr-targets'].map { |target| { :target => uri_decode(target), :out => self } } if params['mashout-trendspottr-targets'].present?
      atts[:media_attributes]     = params['mashout-media'].map{ |media| { :media => uri_decode(media), :out => self } } if params['mashout-media'].present?

      if params['mashout-retweet-targets'].present? and params['mashout-retweet-targets'].any?
        atts[:targets_attributes]         = []
        atts[:retweet_targets_attributes] = []

        params['mashout-retweet-targets'].each do |status_id, targets|
          targets.each do |target|
            if not atts[:targets_attributes].map{|target| target[:target]}.include?(target)
              atts[:targets_attributes]         << { :target    => uri_decode(target),
                                                     :out       => self }
            end
            atts[:retweet_targets_attributes] << { :target    => uri_decode(target),
                                                   :status_id => uri_decode(status_id),
                                                   :out       => self }
          end
        end
      end

      atts
    end

    def uri_decode(value)
      return if value.nil?
      URI.decode(value)
    end
end

