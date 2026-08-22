# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Accounts::Channels::WhatsappUnofficialController, type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:channel) do
    create(:channel_whatsapp,
           account: account,
           provider: 'whatsapp_unofficial',
           phone_number: '15550001111',
           sync_templates: false, validate_provider_config: false)
  end

  before do
    create(:inbox, account: account, channel: channel)
    allow(Whatsapp::CompanionConfig).to receive_messages(
      companion_url: 'http://companion.test',
      companion_token: 'shared-token'
    )
  end

  def auth_headers
    administrator.create_new_auth_token
  end

  def stub_companion(url, body)
    stub_request(:get, url)
      .with(headers: { 'X-Companion-Token' => 'shared-token' })
      .to_return(status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe 'GET #status' do
    it 'proxies the companion status for the channel' do
      stub_companion('http://companion.test/status/15550001111', { status: 'connected' })

      get "/api/v1/accounts/#{account.id}/channels/whatsapp_unofficial/#{channel.id}/status",
          headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['status']).to eq('connected')
    end
  end

  describe 'GET #qr' do
    it 'proxies the companion QR for the channel' do
      stub_companion('http://companion.test/qr/15550001111', { qr: 'data:image/png;base64,xxx', status: 'scanning' })

      get "/api/v1/accounts/#{account.id}/channels/whatsapp_unofficial/#{channel.id}/qr",
          headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['qr']).to eq('data:image/png;base64,xxx')
    end
  end

  describe 'POST #connect' do
    it 'proxies connect to the companion for a matching unofficial channel' do
      stub_request(:post, 'http://companion.test/connect')
        .with(headers: { 'X-Companion-Token' => 'shared-token' },
              body: hash_including(identifier: '15550001111'))
        .to_return(status: 200, body: { status: 'connecting' }.to_json)

      post "/api/v1/accounts/#{account.id}/channels/whatsapp_unofficial/connect",
           params: { whatsapp_unofficial: { phone_number: '15550001111' } },
           headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['status']).to eq('connecting')
    end

    it 'returns not found for a non-unofficial channel' do
      cloud = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                        sync_templates: false, validate_provider_config: false)
      create(:inbox, account: account, channel: cloud)

      post "/api/v1/accounts/#{account.id}/channels/whatsapp_unofficial/connect",
           params: { whatsapp_unofficial: { phone_number: cloud.phone_number } },
           headers: auth_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #logout' do
    it 'proxies logout to the companion for the channel' do
      stub_request(:post, 'http://companion.test/logout/15550001111')
        .with(headers: { 'X-Companion-Token' => 'shared-token' })
        .to_return(status: 200, body: { status: 'logged_out' }.to_json)

      post "/api/v1/accounts/#{account.id}/channels/whatsapp_unofficial/#{channel.id}/logout",
           headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['status']).to eq('logged_out')
    end
  end

  describe 'GET #find' do
    it 'returns the existing unofficial channel for the phone number' do
      get "/api/v1/accounts/#{account.id}/channels/whatsapp_unofficial/find",
          params: { phone_number: '15550001111' },
          headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('channel_id' => channel.id, 'inbox_id' => channel.inbox.id)
    end

    it 'returns not found when no unofficial channel matches' do
      get "/api/v1/accounts/#{account.id}/channels/whatsapp_unofficial/find",
          params: { phone_number: '99999999999' },
          headers: auth_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
