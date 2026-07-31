class Api::V1::Accounts::Integrations::ShopifyController < Api::V1::Accounts::Integrations::BaseController
  include Shopify::IntegrationHelper
  before_action :ensure_shopify_enabled
  before_action -> { Shopify::ApiContext.setup! }, only: [:orders]
  before_action :fetch_hook, except: [:complete_install]
  before_action :check_authorization, only: [:complete_install, :destroy]
  before_action :validate_contact, only: [:orders]

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
    install_pending_shopify_hook(pending_installation)
    head :ok
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

  def install_pending_shopify_hook(pending_installation)
    data = pending_installation.data
    raise_duplicate_shop! if shopify_shop_exists?(data['shop'])

    hook = create_shopify_hook(data)
    pending_installation.consume!
  rescue Shopify::PendingInstallation::CommitOutcomeUnknown
    raise
  rescue ActiveRecord::RecordNotUnique
    raise_duplicate_shop!
  rescue ActiveRecord::RecordInvalid => e
    raise unless e.record.is_a?(Integrations::Hook) && e.record.errors.added?(:reference_id, :taken)

    raise_duplicate_shop!
  rescue StandardError
    hook&.destroy!
    raise
  end

  def create_shopify_hook(data)
    Current.account.hooks.create!(
      app_id: 'shopify',
      access_token: data['access_token'],
      status: 'enabled',
      reference_id: data['shop'],
      settings: {
        scope: data['scope'],
        connected_at: Time.current.utc.iso8601(6),
        installation_id: SecureRandom.uuid
      }
    )
  end

  def shopify_shop_exists?(shop)
    Integrations::Hook.where(app_id: 'shopify').exists?(['LOWER(reference_id) = ?', shop.downcase])
  end

  def raise_duplicate_shop!
    raise Shopify::PendingInstallation::DuplicateShop, 'This Shopify store is already connected'
  end

  def ensure_shopify_enabled
    head :not_found unless Shopify::FeatureGate.enabled?(account: Current.account)
  end

  def contact
    @contact ||= Current.account.contacts.find_by(id: params[:contact_id])
  end

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'shopify')
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
