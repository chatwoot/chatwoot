require 'rails_helper'

RSpec.describe Cloudflare::CheckCustomHostnameService do
  let(:portal) { create(:portal, custom_domain: 'test.example.com') }
  let(:installation_config_api_key) { create(:installation_config, name: 'CLOUDFLARE_API_KEY', value: 'test-api-key') }
  let(:installation_config_zone_id) { create(:installation_config, name: 'CLOUDFLARE_ZONE_ID', value: 'test-zone-id') }

  describe '#perform' do
    context 'when API token or zone ID is not found' do
      it 'returns error when API token is missing' do
        installation_config_zone_id
        service = described_class.new(portal: portal)

        result = service.perform

        expect(result).to eq(errors: ['Cloudflare API token or zone ID not found'])
      end

      it 'returns error when zone ID is missing' do
        installation_config_api_key
        service = described_class.new(portal: portal)

        result = service.perform

        expect(result).to eq(errors: ['Cloudflare API token or zone ID not found'])
      end
    end

    context 'when no hostname ID is found' do
      it 'returns error' do
        installation_config_api_key
        installation_config_zone_id
        portal.update!(custom_domain: nil)
        service = described_class.new(portal: portal)

        result = service.perform

        expect(result).to eq(errors: ['No custom domain found'])
      end
    end

    context 'when API request is made' do
      before do
        installation_config_api_key
        installation_config_zone_id
      end

      context 'when API request fails' do
        it 'returns error response' do
          service = described_class.new(portal: portal)
          error_response = {
            'errors' => [{ 'message' => 'API error' }]
          }

          stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/test-zone-id/custom_hostnames?hostname=test.example.com')
            .to_return(status: 422, body: error_response.to_json, headers: { 'Content-Type' => 'application/json' })

          result = service.perform

          expect(result[:errors]).to eq(error_response['errors'])
        end
      end

      context 'when API request succeeds but no data is returned' do
        it 'returns hostname missing error' do
          service = described_class.new(portal: portal)
          success_response = {
            'result' => []
          }

          stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/test-zone-id/custom_hostnames?hostname=test.example.com')
            .to_return(status: 200, body: success_response.to_json, headers: { 'Content-Type' => 'application/json' })

          result = service.perform

          expect(result).to eq(errors: ['Hostname is missing in Cloudflare'])
        end
      end

      context 'when API request succeeds and data is returned' do
        it 'updates portal SSL settings and returns success' do
          service = described_class.new(portal: portal)
          success_response = {
            'result' => [
              {
                'ownership_verification_http' => {
                  'http_url' => 'http://example.com/.well-known/cf-verification/verification-id',
                  'http_body' => 'verification-body'
                }
              }
            ]
          }

          stub_request(:get, 'https://api.cloudflare.com/client/v4/zones/test-zone-id/custom_hostnames?hostname=test.example.com')
            .to_return(status: 200, body: success_response.to_json, headers: { 'Content-Type' => 'application/json' })

          expect(portal).to receive(:update).with(
            ssl_settings: {
              'cf_verification_id' => 'verification-id',
              'cf_verification_body' => 'verification-body',
              'cf_status' => nil,
              'cf_verification_errors' => ''
            }
          )

          result = service.perform

          expect(result).to eq(data: success_response['result'])
        end
      end
    end
  end
end
