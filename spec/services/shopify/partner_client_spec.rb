require 'rails_helper'

RSpec.describe Shopify::PartnerClient do
  let(:endpoint) { 'https://partners.shopify.com/123/api/2026-07/graphql.json' }
  let(:access_token) { 'partner-secret-token' }
  let(:shop_id) { 'gid://shopify/Shop/5678' }
  let(:response_body) do
    {
      'data' => {
        'activeSubscription' => {
          'shop' => {
            'id' => shop_id,
            'myshopifyDomain' => 'example.myshopify.com'
          },
          'billingPeriod' => 'EVERY_30_DAYS',
          'cancelAtEndOfCycle' => false,
          'trialEndsAt' => nil,
          'currentBillingCycle' => {
            'startTime' => '2026-07-01T00:00:00Z',
            'endTime' => '2026-08-01T00:00:00Z'
          },
          'items' => [{
            'handle' => 'shopify-basic',
            'description' => 'Shopify Basic',
            'price' => {
              'active' => true,
              'currency' => 'USD',
              'amount' => '29.00'
            }
          }]
        },
        'events' => { 'edges' => [] }
      }
    }
  end

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_PARTNER_ORGANIZATION_ID', nil).and_return('123')
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_PARTNER_APP_ID', nil).and_return('gid://shopify/App/456')
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_PARTNER_ACCESS_TOKEN', nil).and_return(access_token)
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_PARTNER_API_VERSION', '2026-07').and_return('2026-07')
  end

  it 'queries the pinned Partner API and returns only normalized subscription data' do
    request_body = nil
    request = stub_request(:post, endpoint)
              .with(headers: { 'X-Shopify-Access-Token' => access_token }) do |provider_request|
                request_body = provider_request.body
              end
              .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

    snapshot = described_class.new.subscription_snapshot(shop_id: shop_id)

    expect(snapshot).to have_attributes(state: 'active', plan_handles: ['shopify-basic'])
    expect(request).to have_been_requested.once
    body = JSON.parse(request_body)
    expect(body['query']).to include('orderBy: OCCURRED_AT_DESC')
    expect(body['variables']).to include(
      'appId' => 'gid://shopify/App/456',
      'shopId' => shop_id
    )
  end

  it 'keeps GraphQL response details and credentials out of provider errors' do
    stub_request(:post, endpoint).to_return(
      status: 200,
      body: {
        errors: [{
          message: "invalid token #{access_token}"
        }]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect do
      described_class.new.subscription_snapshot(shop_id: shop_id)
    end.to raise_error(described_class::ProviderError, 'Shopify Partner API returned GraphQL errors')
  end

  it 'distinguishes a provider failure from a verified inactive subscription' do
    stub_request(:post, endpoint).to_timeout

    expect do
      described_class.new.subscription_snapshot(shop_id: shop_id)
    end.to raise_error(described_class::ProviderError, /Shopify Partner API request failed/)
  end

  it 'does not treat an incomplete provider response as a missing subscription' do
    stub_request(:post, endpoint).to_return(
      status: 200,
      body: { data: {} }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    expect do
      described_class.new.subscription_snapshot(shop_id: shop_id)
    end.to raise_error(described_class::ProviderError, 'Shopify Partner API returned an invalid response')
  end

  it 'fails before making a request when Partner credentials are incomplete' do
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_PARTNER_ACCESS_TOKEN', nil).and_return(nil)
    expect(HTTParty).not_to receive(:post)

    expect do
      described_class.new.subscription_snapshot(shop_id: shop_id)
    end.to raise_error(described_class::ConfigurationError, 'SHOPIFY_PARTNER_ACCESS_TOKEN is required')
  end
end
