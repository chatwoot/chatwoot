class Integrations::Shopify::OrdersService
  REQUIRED_SCOPES = %w[read_customers read_orders].freeze
  MAX_LIMIT = 10
  MAX_LINE_ITEMS = 5

  def initialize(account:)
    @account = account
    @client_service = Integrations::Shopify::ClientService.new(account: account)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def orders_for_contact(email:, phone_number:, limit: MAX_LIMIT)
    Rails.logger.info(
      "[Integrations::Shopify::OrdersService] orders_for_contact account_id=#{@account.id} " \
      "email_present=#{email.present?} phone_present=#{phone_number.present?} limit=#{limit}"
    )

    identifiers = normalized_identifiers(email, phone_number)
    return missing_identifier_result if identifiers[:email].blank? && identifiers[:phone_number].blank?

    client_result = @client_service.fetch_client
    return client_result unless client_result[:ok]

    unless orders_scopes_granted?
      Rails.logger.warn(
        "[Integrations::Shopify::OrdersService] missing_scope account_id=#{@account.id} " \
        "required=#{REQUIRED_SCOPES.join(',')} granted=#{@client_service.granted_scopes.join(',')}"
      )
      return insufficient_scope_result
    end

    customers = fetch_customers(client_result[:data][:client], identifiers[:email], identifiers[:phone_number])
    Rails.logger.info(
      "[Integrations::Shopify::OrdersService] customer_lookup account_id=#{@account.id} " \
      "customers_count=#{customers.length}"
    )
    return no_customer_result if customers.empty?

    orders = fetch_orders(client_result[:data][:client], customers.first['id'], normalized_limit(limit))
    Rails.logger.info(
      "[Integrations::Shopify::OrdersService] orders_lookup account_id=#{@account.id} " \
      "customer_id=#{customers.first['id']} orders_count=#{orders.length}"
    )
    return failure(:no_results, 'No orders found for the customer.') if orders.empty?

    success(
      orders: orders.map { |order| normalize_order(order, client_result[:data][:hook].reference_id) }
    )
  rescue ShopifyAPI::Errors::HttpResponseError => e
    Rails.logger.error("[Integrations::Shopify::OrdersService] Shopify error: #{e.message}")
    failure(:provider_error, 'Shopify order lookup failed.')
  rescue StandardError => e
    Rails.logger.error("[Integrations::Shopify::OrdersService] #{e.class}: #{e.message}")
    failure(:provider_error, 'Shopify order lookup failed.')
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  private

  def normalized_identifiers(email, phone_number)
    {
      email: email.to_s.strip,
      phone_number: phone_number.to_s.strip
    }
  end

  def missing_identifier_result
    Rails.logger.info("[Integrations::Shopify::OrdersService] missing_identifier account_id=#{@account.id}")
    failure(:missing_identifier, 'A contact email or phone number is required.')
  end

  def no_customer_result
    Rails.logger.info("[Integrations::Shopify::OrdersService] no_customer_result account_id=#{@account.id}")
    failure(:no_results, 'No matching Shopify customer found.')
  end

  def orders_scopes_granted?
    @client_service.scopes_include?(REQUIRED_SCOPES)
  end

  def insufficient_scope_result
    failure(
      :insufficient_scope,
      'Shopify integration is missing customer/order read scopes.'
    )
  end

  def fetch_customers(client, email, phone_number)
    query_parts = []
    query_parts << "email:#{email}" if email.present?
    query_parts << "phone:#{phone_number}" if phone_number.present?

    response = client.get(
      path: 'customers/search.json',
      query: {
        query: query_parts.join(' OR '),
        fields: 'id,email,phone'
      }
    )

    response.body['customers'] || []
  end

  def fetch_orders(client, customer_id, limit)
    response = client.get(
      path: 'orders.json',
      query: {
        customer_id: customer_id,
        status: 'any',
        limit: limit,
        fields: 'id,name,created_at,total_price,currency,fulfillment_status,financial_status,line_items'
      }
    )

    response.body['orders'] || []
  end

  def normalize_order(order, shop_domain)
    {
      id: order['id'],
      name: order['name'],
      created_at: order['created_at'],
      total_price: order['total_price'],
      currency: order['currency'],
      financial_status: order['financial_status'],
      fulfillment_status: order['fulfillment_status'],
      line_items: normalize_line_items(order['line_items']),
      admin_url: admin_url(shop_domain, order['id'])
    }
  end

  def normalize_line_items(line_items)
    Array(line_items).first(MAX_LINE_ITEMS).map do |line_item|
      {
        title: line_item['title'],
        quantity: line_item['quantity'],
        price: line_item['price']
      }
    end
  end

  def admin_url(shop_domain, order_id)
    return nil if shop_domain.blank? || order_id.blank?

    "https://#{shop_domain}/admin/orders/#{order_id}"
  end

  def normalized_limit(limit)
    value = limit.to_i
    return MAX_LIMIT if value <= 0

    [value, MAX_LIMIT].min
  end

  def success(data)
    { ok: true, data: data }
  end

  def failure(code, message)
    { ok: false, error: { code: code, message: message } }
  end
end
