require 'rails_helper'

RSpec.describe Cloudflare::DeleteCustomHostnameService do
  let(:hostname_id) { 'hostname-id-123' }
  let(:service) { described_class.new(hostname_id: hostname_id) }

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

    context 'when hostname_id is missing' do
      it 'returns error' do
        service_without_id = described_class.new(hostname_id: '')
        result = service_without_id.perform
        expect(result[:errors]).to eq(['Hostname ID is required'])
      end
    end

    context 'when API request succeeds' do
      it 'returns success' do
        stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/test-zone-id/custom_hostnames/#{hostname_id}")
          .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.perform

        expect(result[:success]).to be_truthy
      end
    end

    context 'when API request fails' do
      it 'returns API errors' do
        error_response = {
          'errors' => [{ 'code' => 1234, 'message' => 'Hostname not found' }]
        }

        stub_request(:delete, "https://api.cloudflare.com/client/v4/zones/test-zone-id/custom_hostnames/#{hostname_id}")
          .to_return(status: 404, body: error_response.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.perform

        expect(result[:errors]).to eq(error_response['errors'])
      end
    end
  end
end
