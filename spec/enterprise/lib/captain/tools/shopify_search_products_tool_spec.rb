require 'rails_helper'

RSpec.describe Captain::Tools::ShopifySearchProductsTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:tool) { described_class.new(assistant) }

  before do
    create(:integrations_hook, :shopify, account: account)
    allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(true)
  end

  describe '#perform' do
    it 'formats successful product search results' do
      service = instance_double(Integrations::Shopify::ProductsService)
      allow(Integrations::Shopify::ProductsService).to receive(:new).with(account: account).and_return(service)
      allow(service).to receive(:search_products).with(query: 'sneakers', limit: 10).and_return(
        {
          ok: true,
          data: {
            products: [
              {
                title: 'Red Sneakers',
                price: '120.00',
                availability: 'In stock',
                storefront_url: 'https://store/products/red-sneakers'
              }
            ]
          }
        }
      )

      result = tool.perform(nil, query: 'sneakers')

      expect(result).to include('Found 1 matching Shopify products:')
      expect(result).to include('Red Sneakers')
      expect(result).to include('https://store/products/red-sneakers')
    end

    it 'returns reconnect guidance for missing scope' do
      service = instance_double(Integrations::Shopify::ProductsService)
      allow(Integrations::Shopify::ProductsService).to receive(:new).with(account: account).and_return(service)
      allow(service).to receive(:search_products).and_return(
        { ok: false, error: { code: :insufficient_scope, message: 'missing scope' } }
      )

      result = tool.perform(nil, query: 'sneakers')

      expect(result).to eq('Shopify integration requires additional permissions. Please reauthorize Shopify integration and try again.')
    end

    it 'returns safe provider error message' do
      service = instance_double(Integrations::Shopify::ProductsService)
      allow(Integrations::Shopify::ProductsService).to receive(:new).with(account: account).and_return(service)
      allow(service).to receive(:search_products).and_raise(StandardError, 'boom')

      result = tool.perform(nil, query: 'sneakers')

      expect(result).to eq('I could not fetch Shopify products right now. Please try again shortly.')
    end
  end
end
