class OutTarget < ActiveRecord::Base
  belongs_to :out
  validates_presence_of :out, :target
end
