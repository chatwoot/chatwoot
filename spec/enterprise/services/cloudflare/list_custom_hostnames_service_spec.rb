require 'rails_helper'

RSpec.describe Cloudflare::ListCustomHostnamesService do
  let(:service) { described_class.new }

  before do
    create(:installation_config, name: 'CLOUDFLARE_API_KEY', value: 'test-api-token')
    create(:installation_config, name: 'CLOUDFLARE_ZONE_ID', value: 'test-zone-id')
  end

  describe '#perform' do
    context 'when API token or zone ID is missing' do
      it 'returns error when api_token is blank' do
        InstallationConfig.find_by(name: 'CLOUDFLARE_API_KEY').update(value: '')
        result = service.perform
        expect(result[:errors]).to eq(['Cloudflare API token or zone ID not found'])
      end

      it 'returns error when zone_id is blank' do
        InstallationConfig.find_by(name: 'CLOUDFLARE_ZONE_ID').update(value: '')
        result = service.perform
        expect(result[:errors]).to eq(['Cloudflare API token or zone ID not found'])
      end
    end

    context 'when API request succeeds' do
      let(:response_body) do
        {
          'success' => true,
          'errors' => [],
          'messages' => [],
          'result' => [
            {
              'id' => '023e105f4ecef8ad9ca31a8372d0c353',
              'hostname' => 'app.example.com',
              'status' => 'active',
              'ssl' => { 'id' => '0d89c70d-ad9f-4843-b99f-6cc0252067e9', 'status' => 'active', 'method' => 'http', 'type' => 'dv' }
            },
            {
              'id' => '124e205f4ecef8ad9ca31a8372d0c454',
              'hostname' => 'portal.example.com',
              'status' => 'pending',
              'ssl' => { 'id' => '1d89c70d-ad9f-4843-b99f-6cc0252067f0', 'status' => 'pending', 'method' => 'http', 'type' => 'dv' }
            }
          ],
          'result_info' => { 'page' => 1, 'per_page' => 20, 'count' => 2, 'total_count' => 2 }
        }
      end

      it 'returns custom hostnames data' do
        stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/test-zone-id/custom_hostnames')
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.perform

        expect(result[:data]).to eq(response_body['result'])
      end
    end

    context 'when API request fails' do
      it 'returns API errors' do
        error_response = {
          'errors' => [{ 'code' => 1234, 'message' => 'API Error' }]
        }

        stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/test-zone-id/custom_hostnames')
          .to_return(status: 400, body: error_response.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.perform

        expect(result[:errors]).to eq(error_response['errors'])
      end
    end
  end
end
