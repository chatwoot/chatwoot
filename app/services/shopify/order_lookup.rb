class Shopify::OrderLookup
  QUERY = <<~GRAPHQL.freeze
    query CustomerOrders($customerQuery: String!, $orderLimit: Int!) {
      customers(first: 1, query: $customerQuery) {
        nodes {
          orders(first: $orderLimit, sortKey: CREATED_AT, reverse: true) {
            nodes {
              legacyResourceId
              email
              createdAt
              displayFinancialStatus
              displayFulfillmentStatus
              totalPriceSet {
                shopMoney {
                  amount
                  currencyCode
                }
              }
            }
          }
        }
      }
    }
  GRAPHQL
  ORDER_LIMIT = 50
  FULFILLMENT_STATUSES = {
    'FULFILLED' => 'fulfilled',
    'PARTIALLY_FULFILLED' => 'partial',
    'RESTOCKED' => 'restocked'
  }.freeze

  class ProviderError < StandardError; end

  def initialize(hook:, contact:)
    @hook = hook
    @contact = contact
  end

  def perform
    response = client.query(query: QUERY, variables: { customerQuery: customer_query, orderLimit: ORDER_LIMIT })
    body = response.body
    raise ProviderError, 'Shopify could not load orders' if body['errors'].present?

    customer = body.fetch('data').fetch('customers').fetch('nodes').first
    return [] unless customer

    customer.fetch('orders').fetch('nodes').map { |order| format_order(order) }
  end

  private

  attr_reader :hook, :contact

  def client
    Shopify::ApiContext.setup!(custom_app: hook.shopify_custom_app)
    session = ShopifyAPI::Auth::Session.new(shop: hook.reference_id, access_token: hook.access_token)
    ShopifyAPI::Clients::Graphql::Admin.new(session: session, api_version: Shopify::ApiContext::API_VERSION)
  end

  def customer_query
    filters = { email: contact.email, phone: contact.phone_number }.compact_blank
    filters.map do |field, value|
      escaped_value = value.gsub(/["\\]/) { |character| "\\#{character}" }
      %(#{field}:"#{escaped_value}")
    end.join(' OR ')
  end

  def format_order(order)
    id = Integer(order.fetch('legacyResourceId'))
    money = order.fetch('totalPriceSet').fetch('shopMoney')
    {
      id: id,
      email: order.fetch('email'),
      created_at: order.fetch('createdAt'),
      total_price: money.fetch('amount'),
      currency: money.fetch('currencyCode'),
      fulfillment_status: FULFILLMENT_STATUSES[order.fetch('displayFulfillmentStatus')],
      financial_status: order.fetch('displayFinancialStatus')&.downcase,
      admin_url: "https://#{hook.reference_id}/admin/orders/#{id}"
    }
  end
end
