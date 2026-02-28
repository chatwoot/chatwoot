require 'rails_helper'

RSpec.describe Integrations::Shopify::ProductsService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }
  let(:shopify_hook) do
    create(
      :integrations_hook,
      :shopify,
      account: account,
      settings: { scope: 'read_customers,read_orders,read_fulfillments,read_products' }
    )
  end
  let(:shopify_client) { instance_double(ShopifyAPI::Clients::Rest::Admin) }
  let(:client_service) { instance_double(Integrations::Shopify::ClientService) }

  before do
    allow(Integrations::Shopify::ClientService).to receive(:new).with(account: account).and_return(client_service)
    allow(client_service).to receive(:fetch_client).and_return(
      {
        ok: true,
        data: {
          client: shopify_client,
          hook: shopify_hook,
          scopes: %w[read_customers read_orders read_fulfillments read_products]
        }
      }
    )
    allow(client_service).to receive(:granted_scopes).and_return(%w[read_customers read_orders read_fulfillments])
  end

  describe '#search_products' do
    it 'returns normalized product fields on success' do
      allow(client_service).to receive(:scopes_include?).with('read_products').and_return(true)
      allow(shopify_client).to receive(:get).and_return(
        Struct.new(:body).new(
          {
            'products' => [
              {
                'id' => 11,
                'title' => 'Red Sneakers',
                'vendor' => 'Acme',
                'product_type' => 'Shoes',
                'handle' => 'red-sneakers',
                'variants' => [{ 'price' => '129.99', 'available' => true }]
              }
            ]
          }
        )
      )

      result = service.search_products(query: 'sneakers')

      expect(result[:ok]).to be true
      expect(result[:data][:products]).to eq(
        [{
          id: 11,
          title: 'Red Sneakers',
          vendor: 'Acme',
          product_type: 'Shoes',
          handle: 'red-sneakers',
          storefront_url: 'https://test-store.myshopify.com/products/red-sneakers',
          price: '129.99',
          availability: 'In stock'
        }]
      )
    end

    it 'returns no_results when products are empty' do
      allow(client_service).to receive(:scopes_include?).with('read_products').and_return(true)
      allow(shopify_client).to receive(:get).and_return(Struct.new(:body).new({ 'products' => [] }))

      result = service.search_products(query: 'sneakers')

      expect(result[:ok]).to be false
      expect(result.dig(:error, :code)).to eq(:no_results)
    end

    it 'falls back to keyword filtering when title search is empty' do
      allow(client_service).to receive(:scopes_include?).with('read_products').and_return(true)
      title_search_empty = Struct.new(:body).new({ 'products' => [] })
      active_products = Struct.new(:body).new(
        {
          'products' => [
            {
              'id' => 22,
              'title' => 'The Collection Snowboard: Liquid',
              'vendor' => 'Snow',
              'product_type' => 'Snowboard',
              'handle' => 'collection-snowboard-liquid',
              'variants' => [{ 'price' => '150.00', 'available' => true }]
            }
          ]
        }
      )
      allow(shopify_client).to receive(:get).and_return(title_search_empty, active_products)

      result = service.search_products(query: 'snowboard')

      expect(result[:ok]).to be true
      expect(result[:data][:products].first[:title]).to eq('The Collection Snowboard: Liquid')
    end

    it 'returns insufficient_scope when read_products is missing' do
      allow(client_service).to receive(:scopes_include?).with('read_products').and_return(false)

      result = service.search_products(query: 'sneakers')

      expect(result[:ok]).to be false
      expect(result.dig(:error, :code)).to eq(:insufficient_scope)
    end

    it 'maps provider exceptions to provider_error' do
      allow(client_service).to receive(:scopes_include?).with('read_products').and_return(true)
      allow(shopify_client).to receive(:get).and_raise(StandardError, 'provider down')

      result = service.search_products(query: 'sneakers')

      expect(result[:ok]).to be false
      expect(result.dig(:error, :code)).to eq(:provider_error)
    end
  end
end
