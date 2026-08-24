require 'rails_helper'

RSpec.describe Linear::CallbacksController, type: :request do
  let(:account) { create(:account) }
  let(:code) { SecureRandom.hex(10) }
  let(:client_secret) { 'test_linear_secret' }
  let(:state) do
    JWT.encode(
      { sub: account.id, iat: Time.current.to_i, exp: 10.minutes.from_now.to_i, aud: 'linear_oauth' },
      client_secret,
      'HS256'
    )
  end
  let(:linear_redirect_uri) { "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{account.id}/settings/integrations/linear" }

  describe 'GET /linear/callback' do
    let(:access_token) { SecureRandom.hex(10) }
    let(:refresh_token) { SecureRandom.hex(10) }
    let(:response_body) do
      {
        'access_token' => access_token,
        'refresh_token' => refresh_token,
        'token_type' => 'Bearer',
        'expires_in' => 7200,
        'scope' => 'read,write'
      }
    end

    before do
      stub_const('ENV', ENV.to_hash.merge('FRONTEND_URL' => 'http://www.example.com'))
      allow(GlobalConfigService).to receive(:load).and_call_original
      allow(GlobalConfigService).to receive(:load).with('LINEAR_CLIENT_SECRET', nil).and_return(client_secret)
      allow(GlobalConfigService).to receive(:load).with('LINEAR_CLIENT_ID', nil).and_return('test_client_id')
    end

    context 'when successful' do
      before do
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'creates a new integration hook', :aggregate_failures do
        expect do
          get linear_callback_path, params: { code: code, state: state }
        end.to change(Integrations::Hook, :count).by(1)

        hook = Integrations::Hook.last
        expect(hook.access_token).to eq(access_token)
        expect(hook.app_id).to eq('linear')
        expect(hook.status).to eq('enabled')
        expect(hook.settings['token_type']).to eq('Bearer')
        expect(hook.settings['expires_in']).to eq(7200)
        expect(hook.settings['scope']).to eq('read,write')
        expect(hook.refresh_token).to eq(refresh_token)
        expect(hook.settings).not_to have_key('refresh_token')
        expect(hook.settings['expires_on']).to be_present
        expect(response).to redirect_to(linear_redirect_uri)
      end
    end

    context 'when the code is missing' do
      before do
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'redirects to the linear_redirect_uri' do
        get linear_callback_path, params: { state: state }
        expect(response).to redirect_to(linear_redirect_uri)
      end
    end

    context 'when state is missing' do
      it 'redirects to frontend root' do
        get linear_callback_path, params: { code: code }
        expect(response).to redirect_to('http://www.example.com')
      end
    end

    context 'when state is invalid' do
      it 'redirects to frontend root' do
        get linear_callback_path, params: { code: code, state: 'invalid-state' }
        expect(response).to redirect_to('http://www.example.com')
      end
    end

    context 'when hook exists and response omits refresh_token' do
      let!(:existing_hook) do
        create(
          :integrations_hook,
          :linear,
          account: account,
          settings: {
            'refresh_token' => 'existing_refresh_token',
            'token_type' => 'Bearer',
            'scope' => 'read,write',
            'expires_on' => 1.day.from_now.utc.to_s
          }
        )
      end
      let(:response_body) do
        {
          'access_token' => access_token,
          'token_type' => 'Bearer',
          'expires_in' => 7200,
          'scope' => 'read,write'
        }
      end

      before do
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'preserves existing refresh token', :aggregate_failures do
        get linear_callback_path, params: { code: code, state: state }

        existing_hook.reload
        expect(existing_hook.access_token).to eq(access_token)
        expect(existing_hook.refresh_token).to eq('existing_refresh_token')
        expect(existing_hook.settings).not_to have_key('refresh_token')
      end
    end

    context 'when hook exists and response omits access_token' do
      let!(:existing_hook) do
        create(
          :integrations_hook,
          :linear,
          account: account,
          access_token: 'existing_access_token',
          settings: {
            'refresh_token' => 'existing_refresh_token',
            'token_type' => 'Bearer',
            'scope' => 'read,write',
            'expires_on' => 1.day.from_now.utc.to_s
          }
        )
      end
      let(:response_body) do
        {
          'refresh_token' => refresh_token,
          'token_type' => 'Bearer',
          'expires_in' => 7200,
          'scope' => 'read,write'
        }
      end

      before do
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'does not overwrite the existing hook', :aggregate_failures do
        expect do
          get linear_callback_path, params: { code: code, state: state }
        end.not_to change(Integrations::Hook, :count)

        existing_hook.reload
        expect(existing_hook.access_token).to eq('existing_access_token')
        expect(existing_hook.refresh_token).to be_nil
        expect(existing_hook.settings['refresh_token']).to eq('existing_refresh_token')
        expect(response).to redirect_to(linear_redirect_uri)
      end
    end

    context 'when the token is invalid' do
      before do
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(
            status: 400,
            body: { error: 'invalid_grant' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'redirects to the linear_redirect_uri' do
        get linear_callback_path, params: { code: code, state: state }
        expect(response).to redirect_to(linear_redirect_uri)
      end
    end

    context 'with a catalog installation state' do
      let(:nonce) { SecureRandom.hex(32) }
      let(:state) do
        JWT.encode(
          {
            sub: account.id,
            iat: Time.current.to_i,
            exp: 10.minutes.from_now.to_i,
            aud: 'linear_oauth',
            installation_id: installation.id,
            nonce: nonce
          },
          client_secret,
          'HS256'
        )
      end
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:installation) do
        create(
          :captain_tool_catalog_installation,
          account: account,
          initiated_by: admin,
          provider_key: 'linear',
          selected_templates: [
            {
              'template_key' => 'get_linked_issue_status',
              'template_version' => '1.0.0',
              'configuration' => {}
            }
          ],
          status: 'awaiting_connection',
          oauth_nonce_digest: Digest::SHA256.hexdigest(nonce)
        )
      end

      before do
        account.enable_features!('captain_tool_catalog')
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'consumes the nonce once, reuses the hook, and resumes the installation', :aggregate_failures do
        existing_hook = create(:integrations_hook, :linear, account: account, access_token: 'old-access-token')

        expect do
          get linear_callback_path, params: { code: code, state: state }
        end.to change(account.captain_custom_tools.catalog, :count).by(1)
                                                                   .and not_change(Integrations::Hook, :count)

        expect(response).to redirect_to(linear_redirect_uri)
        expect(installation.reload.oauth_nonce_digest).to be_nil
        expect(installation).to be_completed
        expect(installation.integration_hook).to eq(existing_hook)
        installed_tool = account.captain_custom_tools.find(installation.resulting_tool_ids.sole)
        expect(installed_tool).to have_attributes(
          provider_key: 'linear',
          template_key: 'get_linked_issue_status',
          integration_hook_id: existing_hook.id
        )

        get linear_callback_path, params: { code: code, state: state }

        expect(response).to redirect_to(linear_redirect_uri)
        expect(a_request(:post, 'https://api.linear.app/oauth/token')).to have_been_made.once
        expect(account.captain_custom_tools.catalog.count).to eq(1)
      end

      it 'rejects the callback before token exchange when encryption becomes unavailable' do
        allow(Chatwoot).to receive(:encryption_configured?).and_return(false)

        get linear_callback_path, params: { code: code, state: state }

        expect(response).to redirect_to(linear_redirect_uri)
        expect(a_request(:post, 'https://api.linear.app/oauth/token')).not_to have_been_made
        expect(installation.reload.oauth_nonce_digest).to eq(Digest::SHA256.hexdigest(nonce))
      end

      it 'expires the installation and rejects its state before token exchange' do
        installation.update!(expires_at: 1.minute.ago)

        get linear_callback_path, params: { code: code, state: state }

        expect(response).to redirect_to(linear_redirect_uri)
        expect(a_request(:post, 'https://api.linear.app/oauth/token')).not_to have_been_made
        expect(installation.reload).to be_expired
      end
    end

    context 'with a cross-account catalog installation state' do
      let(:other_account) { create(:account) }
      let(:nonce) { SecureRandom.hex(32) }
      let(:installation) do
        create(
          :captain_tool_catalog_installation,
          account: other_account,
          initiated_by: create(:user, account: other_account, role: :administrator),
          provider_key: 'linear',
          status: 'awaiting_connection',
          oauth_nonce_digest: Digest::SHA256.hexdigest(nonce)
        )
      end
      let(:state) do
        JWT.encode(
          {
            sub: account.id,
            exp: 10.minutes.from_now.to_i,
            aud: 'linear_oauth',
            installation_id: installation.id,
            nonce: nonce
          },
          client_secret,
          'HS256'
        )
      end

      it 'rejects the state before exchanging the authorization code' do
        get linear_callback_path, params: { code: code, state: state }

        expect(response).to redirect_to(linear_redirect_uri)
        expect(a_request(:post, 'https://api.linear.app/oauth/token')).not_to have_been_made
        expect(installation.reload.oauth_nonce_digest).to eq(Digest::SHA256.hexdigest(nonce))
        expect(account.hooks).to be_empty
      end
    end
  end
end
