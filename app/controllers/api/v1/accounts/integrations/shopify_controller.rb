class Api::V1::Accounts::Integrations::ShopifyController < Api::V1::Accounts::BaseController
  include Shopify::IntegrationHelper
  before_action :fetch_hook, except: [:auth]

  def auth
    shop_domain = params[:shop_domain]
    return render json: { error: 'Shop domain is required' }, status: :unprocessable_entity if shop_domain.blank?

    state = generate_shopify_token(Current.account.id)
    auth_response = ShopifyAPI::Auth::Oauth.begin_auth(shop: shop_domain, redirect_path: redirect_uri, state: state)

    render json: { redirect_url: auth_response[:auth_route] }
  end

  private

  def redirect_uri
    "#{ENV.fetch('FRONTEND_URL', '')}/shopify/callback"
  end

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'shopify')
  end
end
