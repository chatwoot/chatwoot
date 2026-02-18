require 'rails_helper'

describe Whatsapp::Ycloud::ContactService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }
  let(:api_base) { 'https://api.ycloud.com/v2' }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  describe '#create' do
    it 'creates a contact' do
      stub = stub_request(:post, "#{api_base}/contacts")
        .with(body: hash_including({ 'nickname' => 'John', 'phoneNumber' => '+1234567890' }))
        .to_return(status: 200, body: { id: 'ct_001' }.to_json, headers: headers)

      response = service.create(nickname: 'John', phoneNumber: '+1234567890')
      expect(stub).to have_been_requested
      expect(response.parsed_response['id']).to eq('ct_001')
    end
  end

  describe '#list' do
    it 'lists contacts' do
      stub = stub_request(:get, "#{api_base}/contacts?page=1&limit=20")
        .to_return(status: 200, body: { items: [], total: 0 }.to_json, headers: headers)

      service.list
      expect(stub).to have_been_requested
    end
  end

  describe '#retrieve' do
    it 'retrieves a contact' do
      stub = stub_request(:get, "#{api_base}/contacts/ct_001")
        .to_return(status: 200, body: { id: 'ct_001', nickname: 'John' }.to_json, headers: headers)

      service.retrieve('ct_001')
      expect(stub).to have_been_requested
    end
  end

  describe '#update' do
    it 'updates a contact' do
      stub = stub_request(:patch, "#{api_base}/contacts/ct_001")
        .with(body: hash_including({ 'nickname' => 'Jane' }))
        .to_return(status: 200, body: { id: 'ct_001', nickname: 'Jane' }.to_json, headers: headers)

      service.update('ct_001', nickname: 'Jane')
      expect(stub).to have_been_requested
    end
  end

  describe '#delete' do
    it 'deletes a contact' do
      stub = stub_request(:delete, "#{api_base}/contacts/ct_001")
        .to_return(status: 200, body: '{}', headers: headers)

      service.delete('ct_001')
      expect(stub).to have_been_requested
    end
  end

  describe '#list_attributes' do
    it 'lists custom contact attributes' do
      stub = stub_request(:get, "#{api_base}/contact-attributes")
        .to_return(status: 200, body: { items: [] }.to_json, headers: headers)

      service.list_attributes
      expect(stub).to have_been_requested
    end
  end
end
