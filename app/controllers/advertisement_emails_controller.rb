class AdvertisementEmailsController < ApplicationController
  def create
    @advertisement_email = AdvertisementEmail.new(params[:advertisement_email])

    if @advertisement_email.save
      respond_to do |format|
        format.js { render :json => @advertisement_email }
      end
    else
      respond_to do |format|
        format.js { render :json => { :error => @advertisement_email.errors.full_messages.to_sentence + '.' } }
      end
    end
  end
end
