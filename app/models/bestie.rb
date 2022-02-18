class Bestie < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :screen_name
  validates :screen_name, :uniqueness => {:scope => :user_id}
  validate :must_start_with_at_sign

  private
    def must_start_with_at_sign
      errors.add(:screen_name, 'must start with @') if screen_name !~ /@\w+/i
    end
end
