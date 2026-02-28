require 'rails_helper'

RSpec.describe 'Inbox WhatsApp Web API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:api_channel) { create(:channel_api, account: account) }
  let(:inbox) { create(:inbox, account: account, channel: api_channel) }
  let(:base_path) { "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/whatsapp_web" }
  let(:phone) { '77001234567' }
  let(:instance_name) { "cw_#{account.id}_#{phone}" }

  let(:config_payload) do
    {
      evolution_base_url: 'https://evolution.example.com',
      evolution_api_key: 'evo_super_secret',
      phone: phone,
      import_messages: true,
      days_limit_import_messages: 7
    }
  end

  describe 'GET /api/v1/accounts/{account_id}/inboxes/{inbox_id}/whatsapp_web' do
    it 'returns unauthorized for unauthenticated users' do
      get base_path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized for agents' do
      create(:inbox_member, user: agent, inbox: inbox)

      get base_path, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns config without exposing evolution api key value' do
      api_channel.update!(
        additional_attributes: {
          integration_type: 'whatsapp_web',
          whatsapp_web: {
            evolution_base_url: config_payload[:evolution_base_url],
            evolution_api_key: config_payload[:evolution_api_key],
            phone: config_payload[:phone],
            instance_name: instance_name
          }
        }
      )

      get base_path, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body.dig('config', 'evolution_base_url')).to eq(config_payload[:evolution_base_url])
      expect(body.dig('config', 'phone')).to eq(phone)
      expect(body.dig('config', 'instance_name')).to eq(instance_name)
      expect(body.dig('config', 'evolution_api_key')).to be_nil
      expect(body.dig('config', 'evolution_api_key_configured')).to be(true)
    end
  end

  describe 'PATCH /api/v1/accounts/{account_id}/inboxes/{inbox_id}/whatsapp_web' do
    it 'stores evolution config in additional_attributes as whatsapp_web integration' do
      patch base_path, params: config_payload, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      attrs = api_channel.reload.additional_attributes
      expect(attrs['integration_type']).to eq('whatsapp_web')
      expect(attrs.dig('whatsapp_web', 'evolution_base_url')).to eq('https://evolution.example.com')
      expect(attrs.dig('whatsapp_web', 'evolution_api_key')).to eq('evo_super_secret')
      expect(attrs.dig('whatsapp_web', 'phone')).to eq(phone)
      expect(attrs.dig('whatsapp_web', 'instance_name')).to eq(instance_name)
      expect(api_channel.reload.webhook_url).to eq("https://evolution.example.com/chatwoot/webhook/#{instance_name}")
    end

    it 'returns error when phone is already used by another whatsapp web inbox' do
      existing_channel = create(:channel_api, account: account)
      create(:inbox, account: account, channel: existing_channel)
      existing_channel.update!(
        additional_attributes: {
          integration_type: 'whatsapp_web',
          whatsapp_web: {
            phone: phone,
            instance_name: "cw_#{account.id}_existing"
          }
        }
      )

      patch base_path, params: config_payload, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['error']).to include('phone is already used')
    end
  end

  describe 'POST /api/v1/accounts/{account_id}/inboxes/{inbox_id}/whatsapp_web/setup' do
    let(:client) { instance_double(WhatsappWeb::ConnectorClient) }

    before do
      allow(WhatsappWeb::ConnectorClient).to receive(:new).and_return(client)
      allow(client).to receive(:get).with('/instance/fetchInstances').and_return([])
      allow(client).to receive(:post).with('/instance/create', body: { instanceName: instance_name, qrcode: false, integration: 'WHATSAPP-BAILEYS' }).and_return(
        'instance' => {
          'instanceName' => instance_name
        }
      )
      allow(client).to receive(:post).with("/chatwoot/set/#{instance_name}", body: anything).and_return(
        'enabled' => true,
        'accountId' => account.id.to_s
      )
      allow(client).to receive(:get).with("/instance/connectionState/#{instance_name}").and_return(
        'instance' => {
          'instanceName' => instance_name,
          'state' => 'open'
        }
      )
    end

    it 'creates or reuses instance and configures chatwoot integration' do
      post "#{base_path}/setup", params: config_payload, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body.dig('config', 'phone')).to eq(phone)
      expect(body.dig('config', 'instance_name')).to eq(instance_name)
      expect(body.dig('config', 'chatwoot_webhook_url')).to eq("https://evolution.example.com/chatwoot/webhook/#{instance_name}")
      expect(body.dig('setup', 'device', 'instance', 'instanceName')).to eq(instance_name)
      expect(body.dig('setup', 'tenant_chatwoot_config', 'enabled')).to be(true)
      expect(body.dig('setup', 'status', 'is_connected')).to be(true)
      expect(body.dig('setup', 'status', 'is_logged_in')).to be(true)
    end
  end

  describe 'POST /api/v1/accounts/{account_id}/inboxes/{inbox_id}/whatsapp_web/login_qr' do
    let(:client) { instance_double(WhatsappWeb::ConnectorClient) }

    before do
      api_channel.update!(
        additional_attributes: {
          integration_type: 'whatsapp_web',
          whatsapp_web: {
            evolution_base_url: 'https://evolution.example.com',
            evolution_api_key: 'evo_super_secret',
            phone: phone,
            instance_name: instance_name
          }
        }
      )
      allow(WhatsappWeb::ConnectorClient).to receive(:new).and_return(client)
      allow(client).to receive(:get).with("/instance/connect/#{instance_name}", query: { number: phone }).and_return(
        'pairingCode' => 'ABCD1234',
        'base64' => 'data:image/png;base64,abc'
      )
    end

    it 'returns qr and pair code in one call when phone is provided' do
      post "#{base_path}/login_qr",
           params: { instance_name: instance_name, phone: phone },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.dig('login', 'qr_link')).to eq('data:image/png;base64,abc')
      expect(response.parsed_body.dig('login', 'pair_code')).to eq('ABCD1234')
    end
  end

  describe 'POST /api/v1/accounts/{account_id}/inboxes/{inbox_id}/whatsapp_web/remove_device' do
    let(:client) { instance_double(WhatsappWeb::ConnectorClient) }

    before do
      api_channel.update!(
        additional_attributes: {
          integration_type: 'whatsapp_web',
          whatsapp_web: {
            evolution_base_url: 'https://evolution.example.com',
            evolution_api_key: 'evo_super_secret',
            phone: phone,
            instance_name: instance_name
          }
        }
      )
      allow(WhatsappWeb::ConnectorClient).to receive(:new).and_return(client)
      allow(client).to receive(:delete).with("/instance/delete/#{instance_name}").and_return(
        'status' => 'SUCCESS',
        'response' => {
          'message' => 'Instance deleted'
        }
      )
    end

    it 'removes instance from evolution api' do
      post "#{base_path}/remove_device",
           params: { instance_name: instance_name },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.dig('remove_device', 'status')).to eq('SUCCESS')
    end
  end

  describe 'POST /api/v1/accounts/{account_id}/inboxes/{inbox_id}/whatsapp_web/reconnect' do
    let(:client) { instance_double(WhatsappWeb::ConnectorClient) }

    before do
      api_channel.update!(
        additional_attributes: {
          integration_type: 'whatsapp_web',
          whatsapp_web: {
            evolution_base_url: 'https://evolution.example.com',
            evolution_api_key: 'evo_super_secret',
            phone: phone,
            instance_name: instance_name
          }
        }
      )
      allow(WhatsappWeb::ConnectorClient).to receive(:new).and_return(client)
      allow(client).to receive(:post).with("/instance/restart/#{instance_name}").and_return(
        'error' => true,
        'message' => '[object Object]'
      )
      allow(client).to receive(:get).with("/instance/connect/#{instance_name}").and_return(
        'pairingCode' => 'ABCD1234',
        'qrcode' => {
          'base64' => 'data:image/png;base64,abc'
        }
      )
    end

    it 'falls back to connect when restart responds with an error payload' do
      post "#{base_path}/reconnect",
           params: { instance_name: instance_name },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(client).to have_received(:get).with("/instance/connect/#{instance_name}")
      expect(response.parsed_body.dig('reconnect', 'pairingCode')).to eq('ABCD1234')
    end
  end
end
