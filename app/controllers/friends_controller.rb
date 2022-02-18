class FriendsController < ApplicationController
  before_filter :auth_required

  def create
    friend  = Friend.new(params['friend'])

    begin
      twitter_user = current_user.twitter.follow(friend.twitter_user_id)

      # Only create local copy if followed user has public account
      if twitter_user.protected?
        render json: json_response(true, "Follow request sent to #{twitter_user.screen_name}.") and return
      else
        current_user.friends << friend
      end

      render json: json_response
    rescue Twitter::Error => e
      render json: json_response(false, e.to_s) and return
    end
  end

  def destroy
    friend = Friend.find(params['id'])

    if not friend
      render json: json_response(false, 'Invalid id.') and return
    end

    begin
      current_user.twitter.unfollow(friend.twitter_user_id)
      current_user.friends.delete(friend)
    rescue Twitter::Error => e
      render json: json_response(false, e.to_s) and return
    end

    render json: json_response
  end

  protected
    def json_response(success = true, message = '')
      { data: { success: success, message: message } }
    end
end

