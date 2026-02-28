class Captain::Workflows::Nodes::Shopify::GetCustomerOrdersNode < Captain::Workflows::Nodes::Shopify::BaseShopifyNode
  def execute
    customer_id = context[:shopify_customer_id] || node_data['shopify_customer_id']
    return { orders: [], error: 'No Shopify customer ID available' } if customer_id.blank?

    orders = shopify_client.get(
      path: 'orders.json',
      query: {
        customer_id: customer_id,
        status: 'any',
        fields: 'id,email,created_at,total_price,currency,fulfillment_status,financial_status'
      }
    ).body['orders'] || []

    { orders: orders }
  end
end
