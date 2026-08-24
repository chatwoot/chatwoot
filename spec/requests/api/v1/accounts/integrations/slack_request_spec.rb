require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Integrations::Slacks' do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let!(:hook) { create(:integrations_hook, account: account) }

  describe 'POST /api/v1/accounts/{account.id}/integrations/slack' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/integrations/slack", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates hook' do
        hook_builder = double
        expect(hook_builder).to receive(:perform).and_return(hook)
        expect(Integrations::Slack::HookBuilder).to receive(:new).and_return(hook_builder)

        post "/api/v1/accounts/#{account.id}/integrations/slack",
             params: { code: SecureRandom.hex },
             headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eql('slack')
      end
    end

    context 'with a catalog OAuth state' do
      let(:installation) do
        create(
          :captain_tool_catalog_installation,
          account: account,
          initiated_by: admin,
          provider_key: 'slack',
          status: 'awaiting_connection',
          selected_templates: [
            {
              'template_key' => 'find_user_by_email',
              'template_version' => '1.0.0',
              'configuration' => {}
            }
          ],
          oauth_nonce_digest: Digest::SHA256.hexdigest(nonce)
        )
      end
      let(:nonce) { SecureRandom.hex(32) }
      let(:state) do
        Captain::ToolCatalog::SlackOauthState.new(secret: 'slack-client-secret').generate(
          account_id: account.id,
          installation_id: installation.id,
          nonce: nonce
        )
      end
      let(:hook_builder) { instance_double(Integrations::Slack::HookBuilder, perform: hook) }

      before do
        account.enable_features!('captain_tool_catalog')
        hook.update!(
          status: 'disabled',
          settings: { catalog_connected: true, scope: 'users:read.email', workspace_name: 'Support Workspace' }
        )
        allow(GlobalConfigService).to receive(:load).and_call_original
        allow(GlobalConfigService).to receive(:load).with('SLACK_CLIENT_SECRET', nil).and_return('slack-client-secret')
        allow(Integrations::Slack::HookBuilder).to receive(:new)
          .with(account: account, code: 'catalog-code', catalog: true)
          .and_return(hook_builder)
      end

      it 'consumes the nonce once, reuses the disabled catalog connection, and installs the tool', :aggregate_failures do
        expect do
          post "/api/v1/accounts/#{account.id}/integrations/slack",
               params: { code: 'catalog-code', state: state },
               headers: admin.create_new_auth_token,
               as: :json
        end.to change(account.captain_custom_tools.catalog, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(installation.reload).to be_completed
        expect(installation.oauth_nonce_digest).to be_nil
        expect(installation.integration_hook).to eq(hook)
        expect(account.captain_custom_tools.catalog.sole).to have_attributes(
          provider_key: 'slack',
          template_key: 'find_user_by_email',
          integration_hook_id: hook.id
        )

        post "/api/v1/accounts/#{account.id}/integrations/slack",
             params: { code: 'catalog-code', state: state },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq('error' => { 'code' => 'invalid_oauth_state' })
        expect(hook_builder).to have_received(:perform).once
        expect(account.captain_custom_tools.catalog.count).to eq(1)
      end

      it 'rejects a signed state for another account before the token exchange' do
        other_account = create(:account)
        other_admin = create(:user, account: other_account, role: :administrator)
        other_installation = create(
          :captain_tool_catalog_installation,
          account: other_account,
          initiated_by: other_admin,
          provider_key: 'slack',
          status: 'awaiting_connection',
          oauth_nonce_digest: Digest::SHA256.hexdigest(nonce)
        )
        cross_account_state = Captain::ToolCatalog::SlackOauthState.new(secret: 'slack-client-secret').generate(
          account_id: other_account.id,
          installation_id: other_installation.id,
          nonce: nonce
        )

        post "/api/v1/accounts/#{account.id}/integrations/slack",
             params: { code: 'catalog-code', state: cross_account_state },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq('error' => { 'code' => 'invalid_oauth_state' })
        expect(hook_builder).not_to have_received(:perform)
        expect(other_installation.reload.oauth_nonce_digest).to eq(Digest::SHA256.hexdigest(nonce))
      end

      it 'returns a sanitized provider error when the code exchange fails' do
        allow(hook_builder).to receive(:perform).and_raise(Slack::Web::Api::Errors::InvalidAuth.new('invalid_auth'))

        post "/api/v1/accounts/#{account.id}/integrations/slack",
             params: { code: 'catalog-code', state: state },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq('error' => { 'code' => 'slack_oauth_failed' })
        expect(installation.reload.oauth_nonce_digest).to be_nil
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/integrations/slack/auth' do
    let(:installation) do
      create(
        :captain_tool_catalog_installation,
        account: account,
        initiated_by: admin,
        provider_key: 'slack',
        status: 'awaiting_connection',
        selected_templates: [
          {
            'template_key' => 'send_message_to_channel',
            'template_version' => '1.0.0',
            'configuration' => { 'channel_id' => 'C012SUPPORT' }
          }
        ]
      )
    end

    before do
      account.enable_features!('captain_tool_catalog')
      hook.update!(settings: { scope: 'commands' })
      allow(GlobalConfigService).to receive(:load).and_call_original
      allow(GlobalConfigService).to receive(:load).with('SLACK_CLIENT_ID', nil).and_return('slack-client-id')
      allow(GlobalConfigService).to receive(:load).with('SLACK_CLIENT_SECRET', nil).and_return('slack-client-secret')
    end

    it 'derives scopes server-side and binds signed one-time state to the installation' do
      post "/api/v1/accounts/#{account.id}/integrations/slack/auth",
           params: { installation_id: installation.id },
           headers: admin.create_new_auth_token,
           as: :json

      redirect_uri = URI.parse(response.parsed_body.fetch('redirect_url'))
      query = Rack::Utils.parse_nested_query(redirect_uri.query)
      state = JWT.decode(
        query.fetch('state'),
        'slack-client-secret',
        true,
        algorithm: 'HS256',
        aud: 'slack_oauth',
        verify_aud: true
      ).first

      expect(response).to have_http_status(:ok)
      expect(redirect_uri.host).to eq('slack.com')
      expect(query.fetch('scope').split(',')).to contain_exactly('channels:read', 'chat:write', 'commands', 'groups:read')
      expect(query).to include(
        'client_id' => 'slack-client-id',
        'redirect_uri' => "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/slack"
      )
      expect(state).to include('sub' => account.id, 'installation_id' => installation.id)
      expect(installation.reload.oauth_nonce_digest).to eq(Digest::SHA256.hexdigest(state.fetch('nonce')))
    end

    it 'allows only administrators to initiate catalog OAuth' do
      agent = create(:user, account: account, role: :agent)

      post "/api/v1/accounts/#{account.id}/integrations/slack/auth",
           params: { installation_id: installation.id },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(installation.reload.oauth_nonce_digest).to be_nil
    end

    it 'does not start OAuth when credential encryption is unavailable' do
      allow(Chatwoot).to receive(:encryption_configured?).and_return(false)

      post "/api/v1/accounts/#{account.id}/integrations/slack/auth",
           params: { installation_id: installation.id },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq('error' => { 'code' => 'encryption_required' })
      expect(installation.reload.oauth_nonce_digest).to be_nil
    end

    it 'rejects an installation for another provider' do
      installation.update!(provider_key: 'linear')

      post "/api/v1/accounts/#{account.id}/integrations/slack/auth",
           params: { installation_id: installation.id },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq('error' => { 'code' => 'provider_mismatch' })
      expect(installation.reload.oauth_nonce_digest).to be_nil
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/integrations/slack/' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/integrations/slack/", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates hook if the channel id is correct' do
        channel_builder = double
        expect(channel_builder).to receive(:update).and_return(hook)
        expect(Integrations::Slack::ChannelBuilder).to receive(:new).and_return(channel_builder)

        put "/api/v1/accounts/#{account.id}/integrations/slack",
            params: { channel: SecureRandom.hex },
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['hooks'][0]['id']).to eql(hook.id)
      end

      it 'does not update the hook if the channel id is not correct' do
        channel_builder = double
        expect(channel_builder).to receive(:update)
        expect(Integrations::Slack::ChannelBuilder).to receive(:new).and_return(channel_builder)

        put "/api/v1/accounts/#{account.id}/integrations/slack",
            params: { channel: SecureRandom.hex },
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eql('Invalid slack channel. Please try again')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/integrations/slack/list_all_channels' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/integrations/slack/list_all_channels", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates hook if the channel id is correct' do
        channel_builder = double
        expect(channel_builder).to receive(:fetch_channels).and_return([{ 'id' => '1', 'name' => 'channel-1' }])
        expect(Integrations::Slack::ChannelBuilder).to receive(:new).and_return(channel_builder)

        get "/api/v1/accounts/#{account.id}/integrations/slack/list_all_channels",
            params: { channel: SecureRandom.hex },
            headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response).to eql([{ 'id' => '1', 'name' => 'channel-1' }])
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/integrations/slack' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/integrations/slack", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes hook' do
        delete "/api/v1/accounts/#{account.id}/integrations/slack",
               headers: admin.create_new_auth_token
        expect(response).to have_http_status(:success)
        expect(Integrations::Hook.find_by(id: hook.id)).to be_nil
      end
    end
  end
end
