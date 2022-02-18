class Advertisement < ActiveRecord::Base
  validates :image_path, :presence   => true,
                         :uniqueness => true

  class << self
    def current
      where("start_date <= ? AND end_date >= ?", Time.now, Time.now)
    end

    def random
      current_ads = self.current

      if current_ads.any?
        current_ads.sample
      end
    end
  end
end
