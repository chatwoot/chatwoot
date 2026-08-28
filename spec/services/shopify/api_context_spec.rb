require 'rails_helper'

RSpec.describe Shopify::ApiContext do
  before do
    allow(ShopifyAPI::Context).to receive(:setup)
  end

  it 'initializes Shopify API context from global configuration' do
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_ID', nil).and_return('shopify-client-id')
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_SECRET', nil).and_return('shopify-client-secret')

    described_class.setup!

    expect(ShopifyAPI::Context).to have_received(:setup).with(
      api_key: 'shopify-client-id',
      api_secret_key: 'shopify-client-secret',
      api_version: ShopifyAPI::LATEST_SUPPORTED_ADMIN_VERSION,
      scope: 'read_customers,read_orders,read_fulfillments',
      is_embedded: true,
      is_private: false
    )
  end

  it 'uses an Admin API version supported by the pinned client' do
    expect(ShopifyAPI::AdminVersions::SUPPORTED_ADMIN_VERSIONS).to include(described_class::API_VERSION)
  end

  it 'fails before constructing a client when credentials are unavailable' do
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_ID', nil).and_return(nil)
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_SECRET', nil).and_return(nil)

    expect do
      described_class.setup!
    end.to raise_error(described_class::ConfigurationError, 'Shopify API credentials are unavailable')
    expect(ShopifyAPI::Context).not_to have_received(:setup)
  end
end
