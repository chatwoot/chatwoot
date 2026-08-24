require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ProviderPackCompiler do
  subject(:pack) do
    described_class.new(
      pack_path: Rails.root.join('enterprise/config/captain/tool_catalog/providers/shopify')
    ).compile
  end

  it 'compiles six available tools and keeps destructive order tools approval-gated' do
    templates = pack.fetch('templates').index_by { |template| template.fetch('key') }

    expect(templates.values.select { |template| template.fetch('model_visible') }.pluck('key')).to contain_exactly(
      'add_tag_to_current_customer',
      'check_variant_availability',
      'get_current_customer',
      'get_order_tracking_status',
      'list_recent_customer_orders',
      'search_products_and_variants'
    )
    expect(templates.values.reject { |template| template.fetch('model_visible') }.pluck('key')).to contain_exactly(
      'cancel_order',
      'refund_order'
    )
    expect(templates.fetch('add_tag_to_current_customer')).to include(
      'effective_scopes' => %w[read_customers write_customers],
      'risk_class' => 'low_impact_write'
    )
  end

  it 'server-binds customer and order identity and pins all operations to the Shopify tenant endpoint' do
    templates = pack.fetch('templates').index_by { |template| template.fetch('key') }
    contact_steps = templates.values.filter_map do |template|
      template.fetch('recipe').find { |step| step.fetch('operation_key') == 'find_current_customer' }
    end
    order_step = templates.fetch('get_order_tracking_status').fetch('recipe').last

    expect(contact_steps).to all(
      include('bindings' => include('query' => { 'source' => 'shopify_contact_query' }))
    )
    expect(order_step.dig('bindings', 'orderQuery')).to eq(
      'source' => 'shopify_order_query',
      'path' => 'order_number'
    )
    expect(pack.fetch('operations').pluck('request')).to all(
      include('endpoint_strategy' => 'shopify_admin_graphql')
    )
    expect(pack.fetch('operations').pluck('request')).to all(satisfy { |request| request.exclude?('url') })
    expect(pack.dig('provider', 'api_version')).to eq(Captain::ToolCatalog::ShopifyGraphqlClient::API_VERSION)
    expect(pack.to_json).not_to include('access_token', 'customer_id', 'customerId:"', 'myshopify.com/admin')
  end
end
