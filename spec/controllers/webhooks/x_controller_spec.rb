require 'rails_helper'

RSpec.describe 'Webhooks::XController', type: :request do
  let(:client_secret) { 'test-x-secret' }
  let(:event_payload) do
    {
      for_user_id: '12345',
      direct_message_events: [
        {
          message_create: {
            sender_id: '67890',
            target: { recipient_id: '12345' },
            message_data: {
              text: 'Hello from X!',
              id: 'dm-123',
              created_timestamp: Time.current.to_i * 1000
            }
          }
        }
      ]
    }
  end

  def signature_for(body)
    digest = OpenSSL::HMAC.digest('SHA256', client_secret, body)
    Base64.strict_encode64(digest)
  end

  before do
    InstallationConfig.where(name: 'X_API_SECRET').delete_all
    GlobalConfig.clear_cache
  end

  describe 'POST /webhooks/x' do
    it 'enqueues the events job for valid signature' do
      allow(Webhooks::XEventsJob).to receive(:perform_later)

      body = event_payload.to_json
      with_modified_env X_API_SECRET: client_secret do
        post '/webhooks/x',
             params: body,
             headers: {
               'CONTENT_TYPE' => 'application/json',
               'X-Twitter-Webhooks-Signature' => "sha256=#{signature_for(body)}"
             }
      end

      expect(response).to have_http_status(:success)
      expect(Webhooks::XEventsJob).to have_received(:perform_later)
    end

    it 'returns unauthorized for invalid signature' do
      body = event_payload.to_json
      with_modified_env X_API_SECRET: client_secret do
        post '/webhooks/x',
             params: body,
             headers: {
               'CONTENT_TYPE' => 'application/json',
               'X-Twitter-Webhooks-Signature' => 'sha256=invalid'
             }
      end

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized when signature header is missing' do
      body = event_payload.to_json
      with_modified_env X_API_SECRET: client_secret do
        post '/webhooks/x',
             params: body,
             headers: { 'CONTENT_TYPE' => 'application/json' }
      end

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /webhooks/x' do
    it 'responds to CRC challenge with valid token' do
      crc_token = 'test_crc_token_12345'
      expected_response = OpenSSL::HMAC.digest('SHA256', client_secret, crc_token)
      expected_encoded = Base64.strict_encode64(expected_response)

      with_modified_env X_API_SECRET: client_secret do
        get '/webhooks/x', params: { crc_token: crc_token }
      end

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['response_token']).to eq("sha256=#{expected_encoded}")
    end

    it 'returns bad request when crc_token is missing' do
      with_modified_env X_API_SECRET: client_secret do
        get '/webhooks/x'
      end

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns unauthorized when client secret is not configured' do
      with_modified_env X_API_SECRET: nil do
        get '/webhooks/x', params: { crc_token: 'test' }
      end

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
