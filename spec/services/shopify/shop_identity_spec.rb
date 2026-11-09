require 'rails_helper'

RSpec.describe Shopify::ShopIdentity do
  let(:hook) do
    create(
      :integrations_hook,
      :shopify,
      reference_id: 'example.myshopify.com',
      settings: { 'scope' => 'read_orders' }
    )
  end
  let(:client) { instance_double(ShopifyAPI::Clients::Graphql::Admin) }
  let(:response) do
    instance_double(
      ShopifyAPI::Clients::HttpResponse,
      body: {
        'data' => {
          'shop' => {
            'id' => 'gid://shopify/Shop/5678',
            'myshopifyDomain' => 'example.myshopify.com'
          }
        }
      }
    )
  end

  before do
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_ID', nil).and_return('shopify-client-id')
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_SECRET', nil).and_return('shopify-client-secret')
    allow(ShopifyAPI::Context).to receive(:setup)
    allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).and_return(client)
    allow(client).to receive(:query).and_return(response)
  end

  it 'resolves the Shopify shop GID from the authenticated shop' do
    shop_id = described_class.new(hook: hook).shop_id

    expect(shop_id).to eq('gid://shopify/Shop/5678')
    expect(ShopifyAPI::Context).to have_received(:setup).with(
      api_key: 'shopify-client-id',
      api_secret_key: 'shopify-client-secret',
      api_version: ShopifyAPI::LATEST_SUPPORTED_ADMIN_VERSION,
      scope: 'read_customers,read_orders,read_fulfillments',
      is_embedded: true,
      is_private: false
    )
  end

  it 'does not trust an account-editable shop GID in hook settings' do
    hook.update!(settings: hook.settings.merge('shop_id' => 'gid://shopify/Shop/9999'))

    expect(client).to receive(:query).and_return(response)
    expect(described_class.new(hook: hook).shop_id).to eq('gid://shopify/Shop/5678')
  end

  it 'rejects a shop identity that does not match the installed shop' do
    allow(response).to receive(:body).and_return(
      'data' => {
        'shop' => {
          'id' => 'gid://shopify/Shop/9999',
          'myshopifyDomain' => 'other.myshopify.com'
        }
      }
    )

    expect do
      described_class.new(hook: hook).shop_id
    end.to raise_error(described_class::ProviderError, 'Shopify Admin API returned a different shop')
  end
end
