class Api::V1::Accounts::Integrations::ShopifyController < Api::V1::Accounts::BaseController
  include Shopify::IntegrationHelper
  before_action :setup_shopify_context
  before_action :fetch_hook, except: [:auth]

  def auth
    shop_domain = params[:shop_domain]
    return render json: { error: 'Shop domain is required' }, status: :unprocessable_entity if shop_domain.blank?

    state = generate_shopify_token(Current.account.id)
    client_id = GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil)
    scopes = %w[read_customers read_orders read_fulfillments].join(',')

    auth_url = "https://#{shop_domain}/admin/oauth/authorize?"
    auth_url += URI.encode_www_form(
      client_id: client_id,
      scope: scopes,
      redirect_uri: redirect_uri,
      state: state
    )

    render json: { redirect_url: auth_url }
  end

  private

  def redirect_uri
    "#{ENV.fetch('FRONTEND_URL', '')}/shopify/callback"
  end

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'shopify')
  end

  def setup_shopify_context
    shopify_client_id = GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil)
    shopify_client_secret = GlobalConfigService.load('SHOPIFY_CLIENT_SECRET', nil)
    required_scopes = %w[read_customers read_orders read_fulfillments].freeze

    return if shopify_client_id.blank? || shopify_client_secret.blank?

    ShopifyAPI::Context.setup(
      api_key: shopify_client_id,
      api_secret_key: shopify_client_secret,
      api_version: '2025-01'.freeze,
      scope: required_scopes.join(','),
      is_embedded: true,
      is_private: false
    )
  end
end
