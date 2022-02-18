class UserHashtag < ActiveRecord::Base
  belongs_to :user

  validates :user, :presence => true
  validates :tag,  :presence   => true,
                   :format     => { :with => /^\#.+$/, :message => "%{value} is not a valid hashtag" },
                   :uniqueness => { :scope => :user_id, :message => "%{value} has already been created" }

  attr_accessible :tag

  default_scope order(:id)
end
