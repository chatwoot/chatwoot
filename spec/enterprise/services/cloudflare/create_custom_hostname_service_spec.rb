require 'rails_helper'

RSpec.describe Cloudflare::CreateCustomHostnameService do
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

    context 'when no hostname is found' do
      it 'returns error' do
        installation_config_api_key
        installation_config_zone_id
        portal.update(custom_domain: nil)
        service = described_class.new(portal: portal)

        result = service.perform

        expect(result).to eq(errors: ['No hostname found'])
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

          stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/test-zone-id/custom_hostnames')
            .with(headers: { 'Authorization' => 'Bearer test-api-key', 'Content-Type' => 'application/json' },
                  body: { hostname: 'test.example.com', ssl: { method: 'http', type: 'dv' } }.to_json)
            .to_return(status: 422, body: error_response.to_json, headers: { 'Content-Type' => 'application/json' })

          result = service.perform

          expect(result[:errors]).to eq(error_response['errors'])
        end
      end

      context 'when API request succeeds but no data is returned' do
        it 'returns hostname creation error' do
          service = described_class.new(portal: portal)
          success_response = {
            'result' => nil
          }

          stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/test-zone-id/custom_hostnames')
            .with(headers: { 'Authorization' => 'Bearer test-api-key', 'Content-Type' => 'application/json' },
                  body: { hostname: 'test.example.com', ssl: { method: 'http', type: 'dv' } }.to_json)
            .to_return(status: 200, body: success_response.to_json, headers: { 'Content-Type' => 'application/json' })

          result = service.perform

          expect(result).to eq(errors: ['Could not create hostname'])
        end
      end

      context 'when a deleted record for the hostname blocks the create' do
        it 'removes the deleted record and creates the hostname again' do
          base = 'https://api.cloudflare.com/client/v4/zones/test-zone-id/custom_hostnames'
          duplicate = { 'errors' => [{ 'code' => 1406, 'message' => 'Duplicate custom hostname found.' }] }
          created = { 'result' => { 'id' => 'new-id', 'ssl' => { 'status' => 'initializing' } } }

          stub_request(:post, base)
            .to_return({ status: 409, body: duplicate.to_json, headers: { 'Content-Type' => 'application/json' } },
                       { status: 200, body: created.to_json, headers: { 'Content-Type' => 'application/json' } })
          stub_request(:get, "#{base}?hostname=test.example.com")
            .to_return(status: 200, body: { 'result' => [{ 'id' => 'old-id', 'status' => 'deleted' }] }.to_json,
                       headers: { 'Content-Type' => 'application/json' })
          delete_request = stub_request(:delete, "#{base}/old-id").to_return(status: 200, body: {}.to_json)

          result = described_class.new(portal: portal).perform

          expect(delete_request).to have_been_requested
          expect(result).to eq(data: created['result'])
          expect(portal.reload.ssl_settings['cf_status']).to eq('initializing')
        end
      end

      context 'when API request succeeds and data is returned' do
        it 'updates portal SSL settings and returns success' do
          service = described_class.new(portal: portal)
          success_response = {
            'result' => {
              'ownership_verification_http' => {
                'http_url' => 'http://example.com/.well-known/cf-verification/verification-id',
                'http_body' => 'verification-body'
              }
            }
          }
          expect(portal.ssl_settings).to eq({})

          stub_request(:post, 'https://api.cloudflare.com/client/v4/zones/test-zone-id/custom_hostnames')
            .with(headers: { 'Authorization' => 'Bearer test-api-key', 'Content-Type' => 'application/json' },
                  body: { hostname: 'test.example.com', ssl: { method: 'http', type: 'dv' } }.to_json)
            .to_return(status: 200, body: success_response.to_json, headers: { 'Content-Type' => 'application/json' })

          result = service.perform
          expect(portal.ssl_settings).to eq(
            {
              'cf_verification_id' => 'verification-id',
              'cf_verification_body' => 'verification-body',
              'cf_status' => nil,
              'cf_verification_errors' => ''
            }
          )
          expect(result).to eq(data: success_response['result'])
        end
      end
    end
  end
end
