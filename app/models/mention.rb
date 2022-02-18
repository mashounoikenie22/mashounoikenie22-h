class Mention < ActiveRecord::Base
  belongs_to :user
  belongs_to :out
  validates_presence_of :who, :out
end
