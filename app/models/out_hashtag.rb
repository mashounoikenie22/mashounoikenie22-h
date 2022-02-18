class OutHashtag < ActiveRecord::Base
  belongs_to :out
  validates_presence_of :out, :tag
end
