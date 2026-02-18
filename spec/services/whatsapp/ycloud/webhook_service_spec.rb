require 'rails_helper'

describe Whatsapp::Ycloud::WebhookService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }
  let(:api_base) { 'https://api.ycloud.com/v2' }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  describe 'ALL_EVENTS' do
    it 'contains 25 event types' do
      expect(described_class::ALL_EVENTS.length).to eq(25)
    end

    it 'includes all whatsapp event types' do
      expect(described_class::ALL_EVENTS).to include('whatsapp.inbound_message.received')
      expect(described_class::ALL_EVENTS).to include('whatsapp.message.updated')
      expect(described_class::ALL_EVENTS).to include('whatsapp.template.reviewed')
      expect(described_class::ALL_EVENTS).to include('whatsapp.call.connect')
      expect(described_class::ALL_EVENTS).to include('whatsapp.flow.status_change')
    end

    it 'includes contact event types' do
      expect(described_class::ALL_EVENTS).to include('contact.created')
      expect(described_class::ALL_EVENTS).to include('contact.unsubscribe.created')
    end
  end

  describe '#create' do
    it 'creates a webhook endpoint' do
      stub = stub_request(:post, "#{api_base}/webhookEndpoints")
        .with(body: hash_including({ 'url' => 'https://test.com/webhook', 'status' => 'active' }))
        .to_return(status: 200, body: { id: 'wh_001', secret: 'whsec_xxx' }.to_json, headers: headers)

      response = service.create(url: 'https://test.com/webhook', events: ['whatsapp.inbound_message.received'], status: 'active')
      expect(stub).to have_been_requested
      expect(response.parsed_response['id']).to eq('wh_001')
    end
  end

  describe '#list' do
    it 'lists webhook endpoints' do
      stub = stub_request(:get, "#{api_base}/webhookEndpoints?page=1&limit=20")
        .to_return(status: 200, body: { items: [] }.to_json, headers: headers)

      service.list
      expect(stub).to have_been_requested
    end
  end

  describe '#rotate_secret' do
    it 'rotates the webhook secret' do
      stub = stub_request(:post, "#{api_base}/webhookEndpoints/wh_001/rotate-secret")
        .to_return(status: 200, body: { id: 'wh_001', secret: 'whsec_new' }.to_json, headers: headers)

      response = service.rotate_secret('wh_001')
      expect(stub).to have_been_requested
      expect(response.parsed_response['secret']).to eq('whsec_new')
    end
  end

  describe '#delete' do
    it 'deletes a webhook endpoint' do
      stub = stub_request(:delete, "#{api_base}/webhookEndpoints/wh_001")
        .to_return(status: 200, body: '{}', headers: headers)

      service.delete('wh_001')
      expect(stub).to have_been_requested
    end
  end

  describe '#register_full_webhook' do
    it 'creates webhook with all events' do
      stub = stub_request(:post, "#{api_base}/webhookEndpoints")
        .with(body: hash_including({ 'events' => described_class::ALL_EVENTS }))
        .to_return(status: 200, body: { id: 'wh_001' }.to_json, headers: headers)

      service.register_full_webhook
      expect(stub).to have_been_requested
    end
  end
end
