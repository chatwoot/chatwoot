class InfluencerOfferPageController < PublicController
  layout false

  def show
    @token = params[:token]
    render :show
  end
end
