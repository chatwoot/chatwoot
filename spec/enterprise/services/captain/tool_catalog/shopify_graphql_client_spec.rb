require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ShopifyGraphqlClient do
  subject(:executor) { Captain::ToolCatalog::Executor.new(custom_tool: custom_tool) }

  let(:account) { create(:account) }
  let(:hook) do
    create(
      :integrations_hook,
      :shopify,
      account: account,
      access_token: 'shopify-access-secret',
      reference_id: 'acme-store.myshopify.com',
      settings: { scope: 'read_products' }
    )
  end
  let(:definition) do
    {
      'allowed_origins' => ['https://*.myshopify.com'],
      'operations' => [
        {
          'key' => 'get_shop',
          'source' => 'graphql',
          'scopes' => ['read_products'],
          'definition' => 'query GetShop { shop { name } }',
          'request' => {
            'method' => 'POST',
            'endpoint_strategy' => 'shopify_admin_graphql',
            'encoding' => 'graphql',
            'parameters' => []
          }
        }
      ],
      'recipe' => [{ 'operation_key' => 'get_shop', 'bindings' => {} }]
    }
  end
  let(:custom_tool) do
    create(
      :captain_custom_tool,
      :catalog,
      account: account,
      provider_key: 'shopify',
      integration_hook: hook,
      definition: definition,
      output_schema: {
        'type' => 'object',
        'additionalProperties' => false,
        'required' => ['shop'],
        'properties' => {
          'shop' => {
            'type' => 'object',
            'additionalProperties' => false,
            'required' => ['name'],
            'properties' => { 'name' => { 'type' => 'string' } }
          }
        }
      }
    )
  end

  before do
    account.enable_features!('captain_tool_catalog')
    allow(Chatwoot).to receive(:encryption_configured?).and_return(true)
    allow(SafeFetch).to receive(:fetch) do |_url, **_options, &block|
      body = JSON.generate(data: { shop: { name: 'Acme', privateData: 'hidden' } })
      block.call(SafeFetch::Result.new(tempfile: StringIO.new(body), filename: 'response', content_type: 'application/json'))
    end
  end

  it 'derives the pinned tenant endpoint from the trusted hook before attaching the access token' do
    expect(SafeFetch).to receive(:fetch) do |url, **options, &block|
      expect(url).to eq('https://acme-store.myshopify.com/admin/api/2026-07/graphql.json')
      expect(options).to include(
        method: :post,
        headers: {
          'X-Shopify-Access-Token' => 'shopify-access-secret',
          'Content-Type' => 'application/json'
        },
        sensitive_headers: %w[X-Shopify-Access-Token Content-Type]
      )
      expect(JSON.parse(options.fetch(:body))).to eq(
        'query' => 'query GetShop { shop { name } }',
        'variables' => {}
      )
      body = JSON.generate(data: { shop: { name: 'Acme', privateData: 'hidden' } })
      block.call(SafeFetch::Result.new(tempfile: StringIO.new(body), filename: 'response', content_type: 'application/json'))
    end

    expect(executor.perform({})).to eq('shop' => { 'name' => 'Acme' })
  end

  it 'rejects a non-Shopify hook domain before attaching credentials or making a request' do
    hook.update!(reference_id: 'acme-store.myshopify.com.attacker.example')

    expect { executor.perform({}) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) { |error| expect(error.code).to eq('invalid_shopify_domain') }
    expect(SafeFetch).not_to have_received(:fetch)
  end

  it 'requires the Provider Pack to explicitly allow Shopify tenant origins' do
    custom_tool.definition['allowed_origins'] = ['https://api.example.com']

    expect { executor.perform({}) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) { |error| expect(error.code).to eq('origin_not_allowed') }
    expect(SafeFetch).not_to have_received(:fetch)
  end
end
