class Api::V1::Accounts::Integrations::TiendanubeController < Api::V1::Accounts::BaseController
  include Tiendanube::IntegrationHelper
  before_action :fetch_hook, except: [:auth]
  before_action :validate_contact, only: [:orders]

  def auth
    store_id = params[:store_id]
    return render json: { error: 'Store ID is required' }, status: :unprocessable_entity if store_id.blank?

    state = generate_tiendanube_token(Current.account.id)

    auth_url = "https://#{store_id}.mitiendanube.com/apps/authorize/token?"
    auth_url += URI.encode_www_form(
      client_id: client_id,
      response_type: 'code',
      state: state,
      redirect_uri: redirect_uri
    )

    render json: { redirect_url: auth_url }
  end

  def orders
    # Try to fetch from cache first
    cache_key = "tiendanube_orders_#{Current.account.id}_#{params[:contact_id]}"
    cached_orders = Rails.cache.read(cache_key)
    return render json: { orders: cached_orders, cached: true } if cached_orders

    customers = fetch_customers
    return render json: { orders: [] } if customers.empty?

    orders = fetch_orders(customers.first['id'])
    # Cache orders for 5 minutes
    Rails.cache.write(cache_key, orders, expires_in: 5.minutes)
    render json: { orders: orders, cached: false }
  rescue StandardError => e
    Rails.logger.error("Tiendanube orders error: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    # Clear all cached orders for this account
    clear_account_cache

    @hook.destroy!
    head :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def redirect_uri
    "#{ENV.fetch('FRONTEND_URL', '')}/tiendanube/callback"
  end

  def contact
    @contact ||= Current.account.contacts.find_by(id: params[:contact_id])
  end

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'tiendanube')
  end

  def fetch_customers
    query = []
    query << "email:#{contact.email}" if contact.email.present?
    query << "phone:#{contact.phone_number}" if contact.phone_number.present?

    response = tiendanube_request(
      path: '/customers/search',
      params: {
        query: query.join(' OR ')
      }
    )

    response['customers'] || []
  end

  def fetch_orders(customer_id)
    response = tiendanube_request(
      path: '/orders',
      params: {
        customer_id: customer_id,
        fields: 'id,number,status,payment_status,shipping_status,total,currency,created_at'
      }
    )

    orders = response['orders'] || []
    # Limit to 20 orders as per challenge requirements
    orders = orders.first(20)
    orders.map do |order|
      order.merge('admin_url' => "https://#{@hook.reference_id}.mitiendanube.com/admin/orders/#{order['id']}")
    end
  end

  def tiendanube_request(path:, params: {})
    uri = URI("https://api.tiendanube.com/v1/#{@hook.reference_id}#{path}")
    uri.query = URI.encode_www_form(params) if params.any?

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['Authentication'] = "bearer #{@hook.access_token}"
    request['User-Agent'] = 'Chatwoot (contact@chatwoot.com)'

    response = http.request(request)

    case response.code.to_i
    when 200
      JSON.parse(response.body)
    when 401, 403
      raise StandardError, 'Invalid or expired access token. Please reconnect your Tiendanube store.'
    else
      raise StandardError, "Tiendanube API error: #{response.code}"
    end
  end

  def validate_contact
    return unless contact.blank? || (contact.email.blank? && contact.phone_number.blank?)

    render json: { error: 'Contact information missing' },
           status: :unprocessable_entity
  end

  def clear_account_cache
    # Clear all Tiendanube order caches for this account
    # This ensures fresh data after reconnection
    Current.account.contacts.find_each do |contact|
      cache_key = "tiendanube_orders_#{Current.account.id}_#{contact.id}"
      Rails.cache.delete(cache_key)
    end
  end
end
