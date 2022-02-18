class Follower < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :twitter_user_id
  validates_uniqueness_of :twitter_user_id, :scope => :user_id
end
