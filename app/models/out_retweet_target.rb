class OutRetweetTarget < ActiveRecord::Base
  belongs_to :out
  validates_presence_of :out, :status_id, :target
end

