class AuthorizationController < ApplicationController
  def create
    auth = request.env['omniauth.auth']
    unless @auth = Authorization.find_from_hash(auth)
      @auth = Authorization.create_from_hash(auth, current_user)
    end

    self.current_user = @auth.user
    self.synchronize(self.current_user) if (self.current_user.present? && self.current_user.twitter.present?)
    redirect_to dashboard_url
  end

  def failure
    @message = params['message']
  end

  protected
    def synchronize(user)
      if user.synchronize < Time.now
        flash[:notice] = 'It appears like we don\'t have your friends or followers.  Please be patient, it may take several minutes to provision your account.'
      end
    end
end

