# Only the existing Linear and Shopify read operations. Never dispatch arbitrary methods.
module Copilot::V2::ExternalReads
  private

  def fetch_external(resource, inputs)
    rows = if resource == 'shopify_orders'
             shopify_orders(inputs.fetch('contact_id'))
           else
             linear_read(resource, inputs)
           end
    limitations = %w[upstream_pagination_not_exhaustive external_retrieval_not_atomic_database_snapshot]
    limitations << 'shopify_customer_search_not_exhaustive' if resource == 'shopify_orders'
    [rows, limitations]
  end

  def linear_read(resource, inputs) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    processor = Integrations::Linear::ProcessorService.new(account: @account)
    response = case resource
               when 'linear_issues'
                 query = inputs.fetch('query')
                 raise ArgumentError, 'Search query must be nonempty and bounded' unless query.present? && query.size <= 1_000

                 processor.search_issue(query)
               when 'linear_teams' then processor.teams
               when 'linear_team_entities'
                 team_id = inputs.fetch('team_id')
                 # The existing GraphQL team query interpolates this identifier.
                 raise ArgumentError, 'Linear team ID must be a UUID' unless team_id.match?(/\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i)

                 processor.team_entities(team_id)
               when 'linear_linked_issues'
                 conversation = scope('conversations').find(inputs.fetch('conversation_id'))
                 url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{@account.id}/conversations/#{conversation.display_id}"
                 processor.linked_issues(url)
               end
    raise ArgumentError, 'external_read_failed:linear' if response[:error]

    data = response.fetch(:data).as_json
    return [linear_entities(inputs.fetch('team_id'), data)] if resource == 'linear_team_entities'

    data.map { |row| safe_linear_row(row, resource) }
  end

  def linear_entities(id, data)
    %w[users projects states labels].index_with do |key|
      Array(data[key]).map { |row| row.slice('id', 'name') }
    end.merge('id' => id)
  end

  def safe_linear_row(row, resource)
    result = row.slice(*Copilot::V2::VirtualResources::DEFINITIONS.fetch(resource)[:fields])
    result['state'] = row['state'].slice('name', 'color') if row['state'].is_a?(Hash)
    if resource == 'linear_linked_issues' && row['issue'].is_a?(Hash)
      issue = row['issue']
      result['issue'] = issue.slice('id', 'identifier', 'title', 'description', 'priority', 'createdAt', 'url')
      result['issue']['state'] = issue['state'].slice('name', 'color') if issue['state'].is_a?(Hash)
    end
    result.except('metadata')
  end

  def shopify_orders(contact_id) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    contact = scope('contacts').find(contact_id)
    raise ArgumentError, 'Contact information missing' if contact.email.blank? && contact.phone_number.blank?

    hook = external_hook!('shopify')
    session = ShopifyAPI::Auth::Session.new(shop: hook.reference_id, access_token: hook.access_token)
    # Match the existing integration's API version without changing global SDK configuration.
    client = ShopifyAPI::Clients::Rest::Admin.new(session: session, api_version: '2025-01')
    query = []
    query << "email:#{contact.email.to_json}" if contact.email.present?
    query << "phone:#{contact.phone_number.to_json}" if contact.phone_number.present?
    customers = client.get(path: 'customers/search.json', query: { query: query.join(' OR '), fields: 'id,email,phone' }).body['customers'] || []
    matches = customers.select do |customer|
      (contact.email.present? && customer['email'].to_s.casecmp?(contact.email)) ||
        (contact.phone_number.present? && customer['phone'] == contact.phone_number)
    end
    # Even a single returned customer does not prove that an unpaged search exhausted all matches.
    raise ArgumentError, 'needs_clarification:shopify_customer_identity' if matches.size > 1
    return [] if matches.empty?

    fields = Copilot::V2::VirtualResources::DEFINITIONS.fetch('shopify_orders')[:fields] - ['admin_url']
    orders = client.get(path: 'orders.json',
                        query: { customer_id: matches.first.fetch('id'), status: 'any',
                                 fields: fields.join(',') }).body['orders'] || []
    orders.map { |order| order.slice(*fields).merge('admin_url' => "https://#{hook.reference_id}/admin/orders/#{order.fetch('id')}") }
  rescue ShopifyAPI::Errors::HttpResponseError
    raise ArgumentError, 'external_read_failed:shopify'
  end
end
