class Api::V2::Accounts::Shopify::LocationsController < Api::V1::Accounts::BaseController
  def index
    render json: {locations: Current.account.shopify_locations}
  end
end
