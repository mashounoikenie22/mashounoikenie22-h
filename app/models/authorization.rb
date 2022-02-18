class Authorization < ActiveRecord::Base
  TWITTER = 'twitter'
  FACEBOOK = 'facebook'
  belongs_to :user
  validates_presence_of :user_id, :uid, :provider
  validates_uniqueness_of :uid, :scope => :provider
  scope :created_yesterday, lambda { where("created_at BETWEEN ? and ?", (Time.now.yesterday.midnight), Time.now.midnight) }

  def self.find_from_hash(hash)
    find_by_provider_and_uid(hash['provider'], hash['uid'])
  end

  def self.create_from_hash(hash, user = nil)
    user ||= User.create_from_hash!(hash)
    Authorization.create(:user      => user,
                         :uid       => hash['uid'],
                         :provider  => hash['provider'],
                         :secret    => hash['credentials']['secret'],
                         :token     => hash['credentials']['token'])
  end
end

