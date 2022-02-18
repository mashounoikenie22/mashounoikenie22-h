class AdvertisementsController < ApplicationController
  def show
    @advertisement                     = Advertisement.find(params[:id])
    @advertisement_email               = AdvertisementEmail.new
    @advertisement_email.advertisement = @advertisement

    render :layout => nil
  end
end
