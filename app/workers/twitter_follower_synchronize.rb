class TwitterFollowerSynchronize
  @queue = :twitter_follower_synchronize_queue

  def self.perform(user_id)
    user                  = User.find(user_id)

    unless user.twitter.present?
      return
    end

    local_follower_ids    = user.local_follower_ids
    twitter_follower_ids  = user.twitter_ids(:follower_ids, {}, nil)

    do_not_remove_list  = local_follower_ids & twitter_follower_ids
    add_list            = (twitter_follower_ids - do_not_remove_list) - local_follower_ids
    remove_list         = local_follower_ids - twitter_follower_ids

    ActiveRecord::Base.transaction do
      remove_list.uniq.each { |id| user.followers.where(:twitter_user_id => id).each { |follower| follower.destroy } }
    end

    ActiveRecord::Base.transaction do
      add_list.uniq.each { |id| user.followers.create(:twitter_user_id => id) }
    end

    ensure
      Resque.remove_delayed(TwitterFollowerSynchronize, user.id)
      Resque.enqueue_at(6.hours.from_now, TwitterFollowerSynchronize, user.id)
  end
end
