require 'rails_helper'

RSpec.describe Integrations::Shopify::OrdersService do
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
    allow(client_service).to receive(:scopes_include?).with(%w[read_customers read_orders]).and_return(true)
  end

  describe '#orders_for_contact' do
    let(:customer_response) do
      Struct.new(:body).new({ 'customers' => [{ 'id' => 'cust_1' }] })
    end

    let(:orders_response) do
      Struct.new(:body).new(
        {
          'orders' => [
            {
              'id' => 91,
              'name' => '#1001',
              'created_at' => '2026-01-10T10:00:00Z',
              'total_price' => '89.50',
              'currency' => 'USD',
              'financial_status' => 'paid',
              'fulfillment_status' => 'fulfilled',
              'line_items' => [{ 'title' => 'Red Sneakers', 'quantity' => 1, 'price' => '89.50' }]
            }
          ]
        }
      )
    end

    it 'returns normalized orders for email lookup' do
      allow(shopify_client).to receive(:get).with(
        path: 'customers/search.json',
        query: { query: 'email:john@example.com', fields: 'id,email,phone' }
      ).and_return(customer_response)
      allow(shopify_client).to receive(:get).with(
        path: 'orders.json',
        query: {
          customer_id: 'cust_1',
          status: 'any',
          limit: 10,
          fields: 'id,name,created_at,total_price,currency,fulfillment_status,financial_status,line_items'
        }
      ).and_return(orders_response)

      result = service.orders_for_contact(email: 'john@example.com', phone_number: nil)

      expect(result[:ok]).to be true
      expect(result[:data][:orders]).to eq(
        [{
          id: 91,
          name: '#1001',
          created_at: '2026-01-10T10:00:00Z',
          total_price: '89.50',
          currency: 'USD',
          financial_status: 'paid',
          fulfillment_status: 'fulfilled',
          line_items: [{ title: 'Red Sneakers', quantity: 1, price: '89.50' }],
          admin_url: 'https://test-store.myshopify.com/admin/orders/91'
        }]
      )
    end

    it 'returns normalized orders for phone lookup' do
      allow(shopify_client).to receive(:get).with(
        path: 'customers/search.json',
        query: { query: 'phone:+15551234567', fields: 'id,email,phone' }
      ).and_return(customer_response)
      allow(shopify_client).to receive(:get).with(
        path: 'orders.json',
        query: {
          customer_id: 'cust_1',
          status: 'any',
          limit: 10,
          fields: 'id,name,created_at,total_price,currency,fulfillment_status,financial_status,line_items'
        }
      ).and_return(orders_response)

      result = service.orders_for_contact(email: nil, phone_number: '+15551234567')

      expect(result[:ok]).to be true
      expect(result[:data][:orders].first[:id]).to eq(91)
    end

    it 'returns missing_identifier when no identity is available' do
      result = service.orders_for_contact(email: nil, phone_number: nil)

      expect(result[:ok]).to be false
      expect(result.dig(:error, :code)).to eq(:missing_identifier)
    end

    it 'returns no_results when customer is not found' do
      allow(shopify_client).to receive(:get).with(
        path: 'customers/search.json',
        query: { query: 'email:john@example.com', fields: 'id,email,phone' }
      ).and_return(Struct.new(:body).new({ 'customers' => [] }))

      result = service.orders_for_contact(email: 'john@example.com', phone_number: nil)

      expect(result[:ok]).to be false
      expect(result.dig(:error, :code)).to eq(:no_results)
    end

    it 'maps provider exceptions to provider_error' do
      allow(shopify_client).to receive(:get).and_raise(StandardError, 'provider down')

      result = service.orders_for_contact(email: 'john@example.com', phone_number: nil)

      expect(result[:ok]).to be false
      expect(result.dig(:error, :code)).to eq(:provider_error)
    end
  end
end
