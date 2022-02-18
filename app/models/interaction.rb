class Interaction < ActiveRecord::Base
  belongs_to :user
  belongs_to :out
  validates_presence_of :target, :out
end
