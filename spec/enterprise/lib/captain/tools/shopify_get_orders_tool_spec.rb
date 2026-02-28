require 'rails_helper'

RSpec.describe Captain::Tools::ShopifyGetOrdersTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:tool) { described_class.new(assistant) }
  let(:tool_context) { Struct.new(:state).new({ contact: { email: 'john@example.com', phone_number: '+15551234567' } }) }

  before do
    create(:integrations_hook, :shopify, account: account)
    allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(true)
  end

  describe '#perform' do
    it 'formats successful order results' do
      service = instance_double(Integrations::Shopify::OrdersService)
      allow(Integrations::Shopify::OrdersService).to receive(:new).with(account: account).and_return(service)
      allow(service).to receive(:orders_for_contact).with(email: 'john@example.com', phone_number: '+15551234567', limit: 10).and_return(
        {
          ok: true,
          data: {
            orders: [
              {
                name: '#1001',
                created_at: '2026-01-10T10:00:00Z',
                currency: 'USD',
                total_price: '89.50',
                financial_status: 'paid',
                fulfillment_status: 'fulfilled',
                admin_url: 'https://store/admin/orders/91',
                line_items: [{ title: 'Red Sneakers', quantity: 1 }]
              }
            ]
          }
        }
      )

      result = tool.perform(tool_context)

      expect(result).to include('Found 1 Shopify orders:')
      expect(result).to include('#1001')
      expect(result).to include('https://store/admin/orders/91')
    end

    it 'returns missing identity message' do
      service = instance_double(Integrations::Shopify::OrdersService)
      allow(Integrations::Shopify::OrdersService).to receive(:new).with(account: account).and_return(service)
      allow(service).to receive(:orders_for_contact).and_return(
        { ok: false, error: { code: :missing_identifier, message: 'missing' } }
      )

      result = tool.perform(Struct.new(:state).new({ contact: {} }))

      expect(result).to eq('I need the contact email or phone number to look up Shopify orders.')
    end

    it 'falls back to extracting email from current input text when contact identity is missing' do
      service = instance_double(Integrations::Shopify::OrdersService)
      context = Struct.new(:state).new(
        { contact: {}, captain_v2_trace_current_input: 'Where is my order Russel.winfield@example.com?' }
      )

      allow(Integrations::Shopify::OrdersService).to receive(:new).with(account: account).and_return(service)
      allow(service).to receive(:orders_for_contact).with(email: 'Russel.winfield@example.com', phone_number: nil, limit: 10).and_return(
        { ok: false, error: { code: :no_results, message: 'No orders found for the customer.' } }
      )

      result = tool.perform(context)

      expect(result).to eq('No orders found for the customer.')
    end

    it 'uses explicit arguments over inferred state identity' do
      service = instance_double(Integrations::Shopify::OrdersService)
      context = Struct.new(:state).new(
        { contact: {}, captain_v2_trace_current_input: 'Where is my order inferred@example.com?' }
      )

      allow(Integrations::Shopify::OrdersService).to receive(:new).with(account: account).and_return(service)
      allow(service).to receive(:orders_for_contact).with(email: 'explicit@example.com', phone_number: nil, limit: 10).and_return(
        { ok: false, error: { code: :no_results, message: 'No orders found for the customer.' } }
      )

      result = tool.perform(context, email: 'explicit@example.com')

      expect(result).to eq('No orders found for the customer.')
    end

    it 'uses trace history identity when current input is a plain confirmation' do
      service = instance_double(Integrations::Shopify::OrdersService)
      trace_input = [
        { role: 'user', content: 'Where is my order Russel.winfield@example.com?' },
        { role: 'assistant', content: 'Please confirm your email' },
        { role: 'user', content: 'Yes' }
      ].to_json
      context = Struct.new(:state).new(
        { contact: {}, captain_v2_trace_current_input: 'Yes', captain_v2_trace_input: trace_input }
      )

      allow(Integrations::Shopify::OrdersService).to receive(:new).with(account: account).and_return(service)
      allow(service).to receive(:orders_for_contact).with(email: 'Russel.winfield@example.com', phone_number: nil, limit: 10).and_return(
        { ok: false, error: { code: :no_results, message: 'No orders found for the customer.' } }
      )

      result = tool.perform(context)

      expect(result).to eq('No orders found for the customer.')
    end

    it 'returns no result message from service' do
      service = instance_double(Integrations::Shopify::OrdersService)
      allow(Integrations::Shopify::OrdersService).to receive(:new).with(account: account).and_return(service)
      allow(service).to receive(:orders_for_contact).and_return(
        { ok: false, error: { code: :no_results, message: 'No orders found for the customer.' } }
      )

      result = tool.perform(tool_context)

      expect(result).to eq('No orders found for the customer.')
    end

    it 'returns safe provider error message' do
      service = instance_double(Integrations::Shopify::OrdersService)
      allow(Integrations::Shopify::OrdersService).to receive(:new).with(account: account).and_return(service)
      allow(service).to receive(:orders_for_contact).and_raise(StandardError, 'boom')

      result = tool.perform(tool_context)

      expect(result).to eq('I could not fetch Shopify orders right now. Please try again shortly.')
    end
  end
end
