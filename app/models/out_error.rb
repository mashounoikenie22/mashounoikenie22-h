class OutError < ActiveRecord::Base
  belongs_to :out
  validates_presence_of :out, :source, :error

  scope :created_yesterday, lambda { where("created_at BETWEEN ? and ?", (Time.now.yesterday.midnight), Time.now.midnight) }
end

