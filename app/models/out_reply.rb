class OutReply < ActiveRecord::Base
  belongs_to :out
  validates_presence_of :out, :reply
end
