class UserHashtagsController < ApplicationController
  before_filter :auth_required
  before_filter :load_hashtag, :only => [:update, :destroy]

  def new
    @hashtag = UserHashtag.new

    render :partial => 'dashboard/new_hashtag', :object => @hashtag
  end

  def create
    @hashtag = current_user.hashtags.new(params[:user_hashtag])

    if @hashtag.valid?
      @hashtag.save
      render :partial => 'dashboard/hashtag', :object => @hashtag and return
    end

    render :partial => 'dashboard/new_hashtag', :object => @hashtag
  end

  def update
    old_tag = @hashtag.tag
    new_tag = params[:user_hashtag][:tag]
    checked = params[:checked] == 'true'

    @hashtag.update_attributes(params[:user_hashtag])

    unless @hashtag.valid?
      @hashtag.tag = old_tag
    end

    render :partial => 'dashboard/hashtag', :object => @hashtag, :locals => { :checked => checked, :new_tag => new_tag }
  end

  def destroy
    if @hashtag
      @hashtag.delete
    end

    render :nothing => true
  end

  protected
    def load_hashtag
      @hashtag = current_user.hashtags.find_by_id(params[:id])
    end
end
