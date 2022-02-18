class Video < ActiveRecord::Base
  belongs_to :user
  HUMANIZED_ATTRIBUTES = {
    :guid => 'Video',
    :name => 'Video name'
  }.freeze

  validates :guid, :presence   => { :message => 'was not supplied'},
                   :uniqueness => { :scope   => :user_id,
                                    :message => 'has already been saved' }
  validates :name, :presence   => { :message => 'was not supplied'},
                   :uniqueness => { :scope   => :user_id }
  validates :user, :presence   => true

  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
end
