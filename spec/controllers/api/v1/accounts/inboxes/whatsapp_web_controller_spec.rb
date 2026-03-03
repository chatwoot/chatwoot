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
  let(:remote_instance) do
    {
      'id' => 'instance-1',
      'name' => instance_name,
      'connectionStatus' => 'open',
      'ownerJid' => "#{phone}@s.whatsapp.net",
      'profileName' => 'QA Device'
    }
  end

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
      expect(body.dig('config', 'config_sources', 'evolution_api_key')).to eq('stored')
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

    it 'keeps env-backed defaults as defaults until explicitly overridden' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('WHATSAPP_WEB_EVOLUTION_BASE_URL', '').and_return('https://env.evolution.example.com')
      allow(ENV).to receive(:fetch).with('WHATSAPP_WEB_EVOLUTION_API_KEY', '').and_return('env_secret')

      patch base_path, params: { phone: phone }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      attrs = api_channel.reload.additional_attributes.fetch('whatsapp_web')
      expect(attrs).not_to have_key('evolution_base_url')
      expect(attrs).not_to have_key('evolution_api_key')
      expect(attrs['phone']).to eq(phone)
      expect(attrs['instance_name']).to eq(instance_name)

      body = response.parsed_body
      expect(body.dig('config', 'evolution_base_url')).to eq('https://env.evolution.example.com')
      expect(body.dig('config', 'evolution_api_key_configured')).to be(true)
      expect(body.dig('config', 'config_sources', 'evolution_base_url')).to eq('default')
      expect(body.dig('config', 'config_sources', 'evolution_api_key')).to eq('default')
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

    it 'does not allow changing phone after inbox creation' do
      api_channel.update!(
        additional_attributes: {
          integration_type: 'whatsapp_web',
          whatsapp_web: {
            evolution_base_url: config_payload[:evolution_base_url],
            evolution_api_key: config_payload[:evolution_api_key],
            phone: phone,
            instance_name: instance_name
          }
        }
      )

      patch base_path,
            params: { phone: '77009998877' },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['error']).to include('phone cannot be changed')
      expect(api_channel.reload.additional_attributes.dig('whatsapp_web', 'phone')).to eq(phone)
    end
  end

  describe 'POST /api/v1/accounts/{account_id}/inboxes/{inbox_id}/whatsapp_web/setup' do
    let(:client) { instance_double(WhatsappWeb::ConnectorClient) }

    before do
      allow(WhatsappWeb::ConnectorClient).to receive(:new).and_return(client)
      allow(client).to receive(:get).with('/instance/fetchInstances').and_return([], [remote_instance])
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
      expect(body.dig('setup', 'status', 'exists')).to be(true)
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
      allow(client).to receive(:get).with('/instance/fetchInstances').and_return(
        [remote_instance.merge('connectionStatus' => 'close')],
        [remote_instance.merge('connectionStatus' => 'connecting')]
      )
      allow(client).to receive(:post).with("/chatwoot/set/#{instance_name}", body: anything).and_return(
        'enabled' => true,
        'accountId' => account.id.to_s
      )
      allow(client).to receive(:get).with("/instance/connect/#{instance_name}", query: nil).and_return(
        'base64' => 'data:image/png;base64,abc'
      )
      allow(client).to receive(:get).with("/instance/connectionState/#{instance_name}").and_return(
        'instance' => {
          'instanceName' => instance_name,
          'state' => 'connecting'
        }
      )
    end

    it 'returns qr without requesting a pair code by default' do
      post "#{base_path}/login_qr",
           params: { instance_name: instance_name },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.dig('login', 'qr_link')).to eq('data:image/png;base64,abc')
      expect(response.parsed_body.dig('login', 'pair_code')).to be_blank
      expect(response.parsed_body.dig('status', 'state')).to eq('connecting')
      expect(response.parsed_body.dig('status', 'can_cancel')).to be(true)
      expect(response.parsed_body.dig('status', 'can_logout')).to be(false)
      expect(response.parsed_body.dig('status', 'can_request_qr')).to be(true)
      expect(response.parsed_body.dig('status', 'can_request_pair_code')).to be(true)
    end

    it 'reuses the current qr while the instance is already connecting' do
      allow(client).to receive(:get).with('/instance/fetchInstances').and_return(
        [
          remote_instance.merge(
            'connectionStatus' => 'connecting',
            'qrcode' => { 'base64' => 'data:image/png;base64,current' }
          )
        ]
      )
      expect(client).not_to receive(:get).with("/instance/connect/#{instance_name}", query: nil)

      post "#{base_path}/login_qr",
           params: { instance_name: instance_name },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.dig('login', 'qr_link')).to eq('data:image/png;base64,current')
      expect(response.parsed_body.dig('login', 'state')).to eq('connecting')
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
      allow(client).to receive(:get).with('/instance/fetchInstances').and_return(
        [remote_instance.merge('connectionStatus' => 'close')],
        []
      )
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
      expect(response.parsed_body.dig('status', 'state')).to eq('missing')
    end
  end

  describe 'POST /api/v1/accounts/{account_id}/inboxes/{inbox_id}/whatsapp_web/cancel' do
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
      allow(client).to receive(:get).with('/instance/fetchInstances').and_return(
        [remote_instance.merge('connectionStatus' => 'connecting')],
        [remote_instance.merge('connectionStatus' => 'close')]
      )
      allow(client).to receive(:delete).with("/instance/logout/#{instance_name}").and_return(
        'status' => 'SUCCESS',
        'response' => {
          'message' => 'Instance logged out'
        }
      )
      allow(client).to receive(:get).with("/instance/connectionState/#{instance_name}").and_return(
        'instance' => {
          'instanceName' => instance_name,
          'state' => 'close'
        }
      )
    end

    it 'cancels an in-progress connection attempt and returns the updated status' do
      post "#{base_path}/cancel",
           params: { instance_name: instance_name },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(client).to have_received(:delete).with("/instance/logout/#{instance_name}")
      expect(response.parsed_body.dig('cancel', 'status')).to eq('SUCCESS')
      expect(response.parsed_body.dig('status', 'state')).to eq('close')
      expect(response.parsed_body.dig('status', 'can_cancel')).to be(false)
    end
  end

  describe 'POST /api/v1/accounts/{account_id}/inboxes/{inbox_id}/whatsapp_web/logout' do
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
      allow(client).to receive(:get).with('/instance/fetchInstances').and_return(
        [remote_instance.merge('connectionStatus' => 'close')]
      )
      allow(client).to receive(:delete)
    end

    it 'treats already closed instances as a successful no-op' do
      post "#{base_path}/logout",
           params: { instance_name: instance_name },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(client).not_to have_received(:delete)
      expect(response.parsed_body.dig('logout', 'status')).to eq('SUCCESS')
      expect(response.parsed_body.dig('status', 'state')).to eq('close')
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
      allow(client).to receive(:get).with('/instance/fetchInstances').and_return(
        [remote_instance.merge('connectionStatus' => 'close', 'disconnectionReasonCode' => 401)],
        [remote_instance.merge('connectionStatus' => 'connecting')]
      )
      allow(client).to receive(:delete).with("/instance/delete/#{instance_name}").and_return(
        'status' => 'SUCCESS',
        'response' => {
          'message' => 'Instance deleted'
        }
      )
      allow(client).to receive(:post).with('/instance/create', body: { instanceName: instance_name, qrcode: false, integration: 'WHATSAPP-BAILEYS' }).and_return(
        'instance' => {
          'instanceName' => instance_name
        }
      )
      allow(client).to receive(:post).with("/chatwoot/set/#{instance_name}", body: anything).and_return(
        'enabled' => true,
        'accountId' => account.id.to_s
      )
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
      allow(client).to receive(:get).with("/instance/connectionState/#{instance_name}").and_return(
        'instance' => {
          'instanceName' => instance_name,
          'state' => 'connecting'
        }
      )
    end

    it 'resets stale sessions and falls back to connect when restart responds with an error payload' do
      post "#{base_path}/reconnect",
           params: { instance_name: instance_name },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(client).to have_received(:delete).with("/instance/delete/#{instance_name}")
      expect(client).to have_received(:post).with('/instance/create', body: { instanceName: instance_name, qrcode: false, integration: 'WHATSAPP-BAILEYS' })
      expect(client).to have_received(:get).with("/instance/connect/#{instance_name}")
      expect(response.parsed_body.dig('reconnect', 'pairingCode')).to eq('ABCD1234')
      expect(response.parsed_body.dig('status', 'state')).to eq('connecting')
    end
  end
end
