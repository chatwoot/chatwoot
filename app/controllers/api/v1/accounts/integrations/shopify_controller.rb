class Api::V1::Accounts::Integrations::ShopifyController < Api::V1::Accounts::Integrations::BaseController
  include Shopify::IntegrationHelper
  before_action :ensure_shopify_enabled
  before_action -> { Shopify::ApiContext.setup! }, only: [:orders]
  before_action :fetch_hook, except: [:auth, :complete_install]
  before_action :check_authorization, only: [:auth, :complete_install, :destroy]
  before_action :validate_contact, only: [:orders]

  def auth
    shop_domain = params[:shop_domain]
    unless shop_domain.is_a?(String) && Shopify::ShopDomain.valid?(shop_domain)
      return render json: { error: 'Invalid Shopify shop domain' }, status: :unprocessable_entity
    end

    state = generate_shopify_token(Current.account.id)
    raise 'Shopify OAuth is not configured' if client_id.blank? || state.blank?

    oauth_client = OAuth2::Client.new(client_id, client_secret,
                                      site: "https://#{Shopify::ShopDomain.normalize(shop_domain)}",
                                      authorize_url: '/admin/oauth/authorize')
    render json: { redirect_url: oauth_client.auth_code.authorize_url(
      redirect_uri: "#{ENV.fetch('FRONTEND_URL', '')}/shopify/callback",
      scope: REQUIRED_SCOPES.join(','), state: state
    ) }
  end

  def orders
    customers = fetch_customers
    return render json: { orders: [] } if customers.empty?

    orders = fetch_orders(customers.first['id'])
    render json: { orders: orders }
  rescue ShopifyAPI::Errors::HttpResponseError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def complete_install
    pending_installation = Shopify::PendingInstallation.claim(
      token: params[:pending_install_token]
    )
    Shopify::InstallationService.new(account: Current.account, pending_installation: pending_installation).perform
    head :ok
  rescue Shopify::PendingInstallation::AlreadyClaimed => e
    pending_installation&.release!
    render json: { error: e.message }, status: :conflict
  rescue Shopify::PendingInstallation::CommitOutcomeUnknown
    raise
  rescue Shopify::PendingInstallation::Error => e
    pending_installation&.release!
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError
    pending_installation&.release!
    raise
  end

  def destroy
    @hook.destroy!
    head :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def ensure_shopify_enabled
    head :not_found unless Shopify::FeatureGate.enabled?(account: Current.account)
  end

  def contact
    @contact ||= Current.account.contacts.find_by(id: params[:contact_id])
  end

  def fetch_hook
    hooks = Integrations::Hook.where(account: Current.account, app_id: 'shopify')
    hooks = hooks.enabled if action_name == 'orders'
    @hook = hooks.first!
  end

  def fetch_customers
    query = []
    query << "email:#{contact.email}" if contact.email.present?
    query << "phone:#{contact.phone_number}" if contact.phone_number.present?

    shopify_client.get(
      path: 'customers/search.json',
      query: {
        query: query.join(' OR '),
        fields: 'id,email,phone'
      }
    ).body['customers'] || []
  end

  def fetch_orders(customer_id)
    orders = shopify_client.get(
      path: 'orders.json',
      query: {
        customer_id: customer_id,
        status: 'any',
        fields: 'id,email,created_at,total_price,currency,fulfillment_status,financial_status'
      }
    ).body['orders'] || []

    orders.map do |order|
      order.merge('admin_url' => "https://#{@hook.reference_id}/admin/orders/#{order['id']}")
    end
  end

  def shopify_session
    ShopifyAPI::Auth::Session.new(shop: @hook.reference_id, access_token: @hook.access_token)
  end

  def shopify_client
    @shopify_client ||= ShopifyAPI::Clients::Rest::Admin.new(
      session: shopify_session,
      api_version: Shopify::ApiContext::API_VERSION
    )
  end

  def validate_contact
    return unless contact.blank? || (contact.email.blank? && contact.phone_number.blank?)

    render json: { error: 'Contact information missing' },
           status: :unprocessable_entity
  end
end
