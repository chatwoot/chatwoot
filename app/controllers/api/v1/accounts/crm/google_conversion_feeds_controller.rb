class Api::V1::Accounts::Crm::GoogleConversionFeedsController < Api::V1::Accounts::Crm::BaseController
  def create
    authorize Current.account, :update?

    token = Crm::GoogleOffline::FeedToken.fetch_or_create!(Current.account)
    render json: {
      token: token,
      url: "#{request.base_url}/google_conversions/#{token}.csv"
    }, status: :created
  end
end
