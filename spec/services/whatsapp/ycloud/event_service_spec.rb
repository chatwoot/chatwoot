require 'rails_helper'

describe Whatsapp::Ycloud::EventService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }
  let(:api_base) { 'https://api.ycloud.com/v2' }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  describe '#create_definition' do
    it 'creates an event definition' do
      stub = stub_request(:post, "#{api_base}/custom-events/definitions")
        .with(body: hash_including({ 'name' => 'purchase_completed' }))
        .to_return(status: 200, body: { id: 'evtdef_001' }.to_json, headers: headers)

      response = service.create_definition(name: 'purchase_completed', label: 'Purchase Completed')
      expect(stub).to have_been_requested
      expect(response.parsed_response['id']).to eq('evtdef_001')
    end
  end

  describe '#send_event' do
    it 'sends a custom event' do
      stub = stub_request(:post, "#{api_base}/custom-events")
        .with(body: hash_including({ 'eventName' => 'purchase_completed' }))
        .to_return(status: 200, body: { id: 'evt_001' }.to_json, headers: headers)

      response = service.send_event(
        eventName: 'purchase_completed',
        contact: { phoneNumber: '+1234567890' },
        properties: { amount: 99.99 }
      )
      expect(stub).to have_been_requested
      expect(response.parsed_response['id']).to eq('evt_001')
    end
  end

  describe '#create_property_definition' do
    it 'creates a property definition' do
      stub = stub_request(:post, "#{api_base}/custom-events/property-definitions")
        .to_return(status: 200, body: { id: 'prop_001' }.to_json, headers: headers)

      service.create_property_definition(eventDefinitionId: 'evtdef_001', name: 'amount', type: 'number')
      expect(stub).to have_been_requested
    end
  end

  describe '#delete_property_definition' do
    it 'deletes a property definition' do
      stub = stub_request(:delete, "#{api_base}/custom-events/property-definitions/prop_001")
        .to_return(status: 200, body: '{}', headers: headers)

      service.delete_property_definition('prop_001')
      expect(stub).to have_been_requested
    end
  end
end
