class CacheVerifiedTwitterUser
  @queue = :cache_verified_twitter_user_queue
   
  def self.perform
    remote_verified_ids   = VerifiedTwitterUser.remote_twitter_ids
    local_verified_ids    = VerifiedTwitterUser.local_twitter_ids
    
    do_not_remove_list    = local_verified_ids & remote_verified_ids
    add_list              = remote_verified_ids - do_not_remove_list
    remove_list           = local_verified_ids - remote_verified_ids

    VerifiedTwitterUser.remove_verified(remove_list)
    VerifiedTwitterUser.add_verified(add_list)
  end
end
