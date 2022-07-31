class Api::V1::Accounts::Integrations::ShopifyController < Api::V1::Accounts::BaseController
  before_action :fetch_shopify, only: [:update, :destroy]
  before_action :check_authorization?

  def index
    @shopify = Current.account.shopify_integrations
    render json: @shopify
  end

  def create
    @shopify = Current.account.shopify_integrations.new(shopify_params)
    @shopify.save!
    render json: @shopify
  end

  def update
    @shopify.update!(shopify_params)
  end

  def destroy
    @shopify.destroy!
    head :ok
  end

  private

  def shopify_params
    params.require(:shopify).permit(:api_key, :api_secret, :account_name, :redirect_url)
  end

  def fetch_shopify
    @shopify = Current.account.shopify_integrations.find(params[:id])
  end

  def check_authorization?
    authorize(:shopify)
  end
end
