require 'rails_helper'

describe Whatsapp::Ycloud::FlowService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }
  let(:api_base) { 'https://api.ycloud.com/v2' }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  describe '#create' do
    it 'creates a flow' do
      stub = stub_request(:post, "#{api_base}/whatsapp/flows")
        .to_return(status: 200, body: { id: 'flow_001', status: 'DRAFT' }.to_json, headers: headers)

      response = service.create(name: 'Support Flow', wabaId: 'waba_123', categories: ['CUSTOMER_SUPPORT'])
      expect(stub).to have_been_requested
      expect(response.parsed_response['id']).to eq('flow_001')
    end
  end

  describe '#list' do
    it 'lists flows with pagination' do
      stub = stub_request(:get, "#{api_base}/whatsapp/flows?page=1&limit=20")
        .to_return(status: 200, body: { items: [], total: 0 }.to_json, headers: headers)

      service.list
      expect(stub).to have_been_requested
    end
  end

  describe '#retrieve' do
    it 'retrieves a specific flow' do
      stub = stub_request(:get, "#{api_base}/whatsapp/flows/flow_001")
        .to_return(status: 200, body: { id: 'flow_001' }.to_json, headers: headers)

      service.retrieve('flow_001')
      expect(stub).to have_been_requested
    end
  end

  describe '#publish' do
    it 'publishes a draft flow' do
      stub = stub_request(:post, "#{api_base}/whatsapp/flows/flow_001/publish")
        .to_return(status: 200, body: { id: 'flow_001', status: 'PUBLISHED' }.to_json, headers: headers)

      response = service.publish('flow_001')
      expect(stub).to have_been_requested
      expect(response.parsed_response['status']).to eq('PUBLISHED')
    end
  end

  describe '#deprecate' do
    it 'deprecates a published flow' do
      stub = stub_request(:post, "#{api_base}/whatsapp/flows/flow_001/deprecate")
        .to_return(status: 200, body: { id: 'flow_001', status: 'DEPRECATED' }.to_json, headers: headers)

      service.deprecate('flow_001')
      expect(stub).to have_been_requested
    end
  end

  describe '#delete' do
    it 'deletes a draft flow' do
      stub = stub_request(:delete, "#{api_base}/whatsapp/flows/flow_001")
        .to_return(status: 200, body: '{}', headers: headers)

      service.delete('flow_001')
      expect(stub).to have_been_requested
    end
  end

  describe '#update_metadata' do
    it 'updates flow metadata' do
      stub = stub_request(:patch, "#{api_base}/whatsapp/flows/flow_001/metadata")
        .to_return(status: 200, body: { id: 'flow_001' }.to_json, headers: headers)

      service.update_metadata('flow_001', name: 'Updated Flow')
      expect(stub).to have_been_requested
    end
  end

  describe '#update_structure' do
    it 'updates flow JSON structure' do
      stub = stub_request(:patch, "#{api_base}/whatsapp/flows/flow_001/structure")
        .to_return(status: 200, body: { id: 'flow_001' }.to_json, headers: headers)

      service.update_structure('flow_001', flowJson: '{}')
      expect(stub).to have_been_requested
    end
  end

  describe '#preview' do
    it 'generates preview URL' do
      stub = stub_request(:get, "#{api_base}/whatsapp/flows/flow_001/preview")
        .to_return(status: 200, body: { previewUrl: 'https://preview.example.com' }.to_json, headers: headers)

      response = service.preview('flow_001')
      expect(stub).to have_been_requested
      expect(response.parsed_response['previewUrl']).to be_present
    end
  end
end
