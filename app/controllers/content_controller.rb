class ContentController < ApplicationController
  def home
    if signed_in?
      redirect_to dashboard_url
    else
      render :layout => 'application'
    end
  end

  def about_us
  end

  def blog
  end

  def terms_and_conditions
  end

  def privacy_policy
  end

  def contact_us
    @message = Message.new
  end

  def message
    @message = Message.new(params[:message])

    if @message.valid?
      ContactMailer.new_message(@message).deliver
      flash.now[:notice] = "Message was successfully sent."
    else
      flash.now[:error] = "Please fill all fields and make sure they are valid."
    end

    render :contact_us
  end

  def signup_iframe
    render :layout => nil
  end
end

