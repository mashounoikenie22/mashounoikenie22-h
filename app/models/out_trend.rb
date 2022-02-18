class OutTrend < ActiveRecord::Base
  belongs_to :out
  validates_presence_of :out, :trend
end
