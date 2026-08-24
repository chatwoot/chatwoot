require 'rails_helper'

RSpec.describe Captain::ToolCatalog::Executor do
  let(:account) { create(:account) }
  let(:pack) do
    Captain::ToolCatalog::ProviderPackCompiler.new(
      pack_path: Rails.root.join('enterprise/config/captain/tool_catalog/providers/shopify')
    ).compile
  end
  let(:template) do
    pack.fetch('templates').find { |candidate| candidate.fetch('key') == 'get_order_tracking_status' }
  end
  let(:hook) do
    create(
      :integrations_hook,
      :shopify,
      account: account,
      access_token: 'shopify-access-secret',
      reference_id: 'acme-store.myshopify.com',
      settings: { scope: 'read_customers,read_orders' }
    )
  end
  let(:custom_tool) do
    attributes = Captain::ToolCatalog::SnapshotBuilder.new(
      pack: pack,
      entry: { template: template, configuration: {} },
      integration_hook: hook
    ).attributes
    account.captain_custom_tools.create!(attributes)
  end
  let(:executor) do
    described_class.new(
      custom_tool: custom_tool,
      state: {
        contact: {
          email: 'customer@example.com',
          phone_number: '+15555550100'
        }
      }
    )
  end
  let(:provider_responses) do
    [
      {
        data: {
          customers: {
            nodes: [{ id: 'gid://shopify/Customer/1001' }]
          }
        }
      },
      {
        data: {
          customer: {
            orders: {
              nodes: [
                {
                  id: 'gid://shopify/Order/2001',
                  name: '#1001',
                  createdAt: '2026-08-20T10:00:00Z',
                  displayFinancialStatus: 'PAID',
                  displayFulfillmentStatus: 'FULFILLED',
                  privateData: 'must-not-reach-model',
                  fulfillments: [
                    {
                      id: 'gid://shopify/Fulfillment/3001',
                      status: 'SUCCESS',
                      displayStatus: 'IN_TRANSIT',
                      estimatedDeliveryAt: '2026-08-25T10:00:00Z',
                      trackingInfo: [{ company: 'Carrier', number: 'TRACK1001', url: 'https://tracking.example/1001' }]
                    }
                  ]
                }
              ]
            }
          }
        }
      }
    ]
  end

  before do
    account.enable_features!('captain_tool_catalog')
    allow(Chatwoot).to receive(:encryption_configured?).and_return(true)
  end

  it 'builds exact identity queries server-side and restricts order lookup to the matched customer' do
    requests = []
    allow(SafeFetch).to receive(:fetch) do |url, **options, &block|
      requests << { url: url, body: JSON.parse(options.fetch(:body)) }
      body = JSON.generate(provider_responses.shift)
      block.call(SafeFetch::Result.new(tempfile: StringIO.new(body), filename: 'response', content_type: 'application/json'))
    end

    result = executor.perform(order_number: '#1001')

    expect(requests.pluck(:url)).to eq(
      Array.new(2, 'https://acme-store.myshopify.com/admin/api/2026-07/graphql.json')
    )
    expect(requests.first.dig(:body, 'variables')).to eq(
      'query' => 'email:"customer@example.com" OR phone:"+15555550100"'
    )
    expect(requests.second.dig(:body, 'variables')).to eq(
      'customerId' => 'gid://shopify/Customer/1001',
      'orderQuery' => 'name:"1001"'
    )
    expect(requests.second.dig(:body, 'query')).to include('customer(id: $customerId)')
    expect(result.dig('customer', 'orders', 'nodes', 0)).not_to have_key('privateData')
    expect(result.to_json).not_to include('must-not-reach-model')
  end

  it 'rejects model-supplied customer identity before making a provider request' do
    allow(SafeFetch).to receive(:fetch)

    expect { executor.perform(order_number: '#1001', customer_id: 'gid://shopify/Customer/9999') }
      .to raise_error(Captain::ToolCatalog::ExecutionError) { |error| expect(error.code).to eq('invalid_tool_input') }
    expect(SafeFetch).not_to have_received(:fetch)
  end

  it 'does not call Shopify when the current contact has no usable identity' do
    executor = described_class.new(custom_tool: custom_tool, state: { contact: {} })
    allow(SafeFetch).to receive(:fetch)

    expect { executor.perform(order_number: '#1001') }
      .to raise_error(Captain::ToolCatalog::ExecutionError) { |error| expect(error.code).to eq('binding_unavailable') }
    expect(SafeFetch).not_to have_received(:fetch)
  end
end
