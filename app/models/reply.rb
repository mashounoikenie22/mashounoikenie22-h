class Reply < ActiveRecord::Base
  belongs_to :user
  belongs_to :out
  validates_presence_of :status_id, :out
end
