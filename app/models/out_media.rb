class OutMedia < ActiveRecord::Base
  belongs_to :out
  validates_presence_of :out, :media
end

