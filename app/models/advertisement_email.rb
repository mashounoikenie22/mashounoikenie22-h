class AdvertisementEmail < ActiveRecord::Base
  belongs_to :advertisement

  attr_accessible :advertisement_id, :email

  validates :advertisement, :presence => true
  validates :email, :presence   => true,
                    :uniqueness => { :scope   => :advertisement_id,
                                     :message => 'can only be used once' },
                    :format => { :with => /\A[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\Z/i }

end
