class Captain::Workflows::Nodes::Shopify::SearchCustomerNode < Captain::Workflows::Nodes::Shopify::BaseShopifyNode
  def execute
    query = build_search_query
    return { customers: [], error: 'No contact email or phone available' } if query.blank?

    customers = shopify_client.get(
      path: 'customers/search.json',
      query: { query: query, fields: 'id,email,phone,first_name,last_name' }
    ).body['customers'] || []

    context[:shopify_customer_id] = customers.first&.dig('id')
    { customers: customers }
  end

  private

  def build_search_query
    parts = []
    parts << "email:#{contact.email}" if contact&.email.present?
    parts << "phone:#{contact&.phone_number}" if contact&.phone_number.present?
    parts.join(' OR ').presence
  end
end
