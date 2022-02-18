class VerifiedTwitterUser < ActiveRecord::Base
  validates_presence_of :user_id
  validates_uniqueness_of :user_id

  def self.local_twitter_ids
    self.find(:all, :select => :user_id).map(&:user_id)
  end

  def self.remote_twitter_ids
    User.page_through_twitter_ids(User.mashoutable_twitter, :friend_ids, {:screen_name => 'verified'})
  end

  def self.remove_verified(remove_list)
    ActiveRecord::Base.transaction do
      VerifiedTwitterUser.where(:user_id => remove_list).each do |local_verified_twitter_user|
        local_verified_twitter_user.destroy
      end
    end
  end

  def self.add_verified(add_list)
    ActiveRecord::Base.transaction do
      add_list.each { |twitter_verified_id| VerifiedTwitterUser.create(:user_id => twitter_verified_id) }
    end
  end
end

