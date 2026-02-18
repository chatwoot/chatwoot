require 'rails_helper'

describe Whatsapp::Ycloud::TemplateService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }
  let(:api_base) { 'https://api.ycloud.com/v2' }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  describe '#create' do
    it 'posts template creation request' do
      stub = stub_request(:post, "#{api_base}/whatsapp/templates")
        .with(body: hash_including({ 'name' => 'hello', 'language' => 'en_US', 'category' => 'UTILITY' }))
        .to_return(status: 200, body: { name: 'hello', status: 'PENDING' }.to_json, headers: headers)

      response = service.create(name: 'hello', language: 'en_US', category: 'UTILITY', components: [])
      expect(stub).to have_been_requested
      expect(response.code).to eq(200)
    end
  end

  describe '#list' do
    it 'fetches paginated templates' do
      stub = stub_request(:get, "#{api_base}/whatsapp/templates?page=1&limit=100")
        .to_return(status: 200, body: { items: [], total: 0 }.to_json, headers: headers)

      response = service.list
      expect(stub).to have_been_requested
      expect(response.parsed_response['total']).to eq(0)
    end
  end

  describe '#retrieve' do
    it 'fetches specific template' do
      stub = stub_request(:get, "#{api_base}/whatsapp/templates/hello/en_US")
        .to_return(status: 200, body: { name: 'hello', language: 'en_US' }.to_json, headers: headers)

      response = service.retrieve('hello', 'en_US')
      expect(stub).to have_been_requested
      expect(response.parsed_response['name']).to eq('hello')
    end
  end

  describe '#update' do
    it 'patches template' do
      stub = stub_request(:patch, "#{api_base}/whatsapp/templates/hello/en_US")
        .with(body: hash_including({ 'category' => 'MARKETING' }))
        .to_return(status: 200, body: { name: 'hello', category: 'MARKETING' }.to_json, headers: headers)

      response = service.update('hello', 'en_US', category: 'MARKETING')
      expect(stub).to have_been_requested
      expect(response.parsed_response['category']).to eq('MARKETING')
    end
  end

  describe '#delete' do
    it 'deletes specific language template' do
      stub = stub_request(:delete, "#{api_base}/whatsapp/templates/hello/en_US")
        .to_return(status: 200, body: '{}', headers: headers)

      service.delete('hello', 'en_US')
      expect(stub).to have_been_requested
    end
  end

  describe '#delete_all' do
    it 'deletes all language variants' do
      stub = stub_request(:delete, "#{api_base}/whatsapp/templates/hello")
        .to_return(status: 200, body: '{}', headers: headers)

      service.delete_all('hello')
      expect(stub).to have_been_requested
    end
  end
end
