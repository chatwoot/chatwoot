require 'rails_helper'

RSpec.describe 'WhapiChannelsController', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'POST /api/v1/accounts/:account_id/whapi_channels' do
    it 'validates name param' do
      post "/api/v1/accounts/#{account.id}/whapi_channels",
           headers: admin.create_new_auth_token,
           params: { name: '' },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to match(/name is required|invalid name/)
    end

    it 'creates inbox and channel and sets provider_config' do
      # Partner endpoints
      stub_request(:get, /\/projects$/).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { projects: [{ id: 'proj_1' }] }.to_json
      )
      stub_request(:put, /\/channels$/).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { id: 'chan_1', token: 'tok_1' }.to_json
      )
      # Channel-level webhook
      stub_request(:patch, /\/settings$/).to_return(status: 200, body: { ok: true }.to_json, headers: { 'Content-Type' => 'application/json' })

      post "/api/v1/accounts/#{account.id}/whapi_channels",
           headers: admin.create_new_auth_token,
           params: { name: 'My Inbox' },
           as: :json

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data['name']).to eq('My Inbox')
      expect(data['channel_type']).to eq('Channel::Whatsapp')
      expect(data['provider']).to eq('whapi')
      expect(data['provider_config']).to include('whapi_channel_id' => 'chan_1', 'connection_status' => 'pending')
    end
  end

  describe 'GET /api/v1/accounts/:account_id/whapi_channels/:id/qr_code' do
    let(:channel) do
      create(:channel_whatsapp,
             account: account,
             provider: 'whapi',
             phone_number: 'pending:chan_1',
             provider_config: { 'whapi_channel_id' => 'chan_1', 'whapi_channel_token' => 'tok_1', 'connection_status' => 'pending' },
             sync_templates: false,
             validate_provider_config: false)
    end
    let(:inbox) { create(:inbox, account: account, channel: channel) }

    it 'returns base64 QR image when successful' do
      stub_request(:get, /\/users\/login$/).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { qr: 'B64QR', expires_in: 20 }.to_json
      )

      get "/api/v1/accounts/#{account.id}/whapi_channels/#{inbox.id}/qr_code",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data['image_base64']).to eq('B64QR')
      expect(data['poll_in']).to be >= 15
    end

    it 'returns 422 when not a whapi inbox' do
      other_inbox = create(:inbox, account: account)
      get "/api/v1/accounts/#{account.id}/whapi_channels/#{other_inbox.id}/qr_code",
          headers: admin.create_new_auth_token,
          as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/whapi_channels/:id/retry_webhook' do
    let(:channel) do
      create(:channel_whatsapp,
             account: account,
             provider: 'whapi',
             phone_number: '1234567890',
             provider_config: { 'whapi_channel_id' => 'chan_1', 'whapi_channel_token' => 'tok_1', 'webhook_retry_needed' => true },
             sync_templates: false,
             validate_provider_config: false)
    end
    let(:inbox) { create(:inbox, account: account, channel: channel) }

    it 'retries webhook setup successfully' do
      stub_request(:patch, /\/settings$/).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { ok: true }.to_json
      )

      post "/api/v1/accounts/#{account.id}/whapi_channels/#{inbox.id}/retry_webhook",
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data['message']).to eq('Webhook configured successfully')
      expect(data).to have_key('webhook_url')
    end

    it 'returns 422 when not a whapi inbox' do
      other_inbox = create(:inbox, account: account)
      post "/api/v1/accounts/#{account.id}/whapi_channels/#{other_inbox.id}/retry_webhook",
           headers: admin.create_new_auth_token,
           as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
