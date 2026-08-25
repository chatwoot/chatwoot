require 'rails_helper'

RSpec.describe Pathors::CallbacksController, type: :request do
  let(:account) { create(:account) }
  let(:code) { SecureRandom.hex(10) }
  let(:connect_secret) { 'test_connect_secret' }
  let(:state) do
    JWT.encode({ account_id: account.id, iat: Time.current.to_i, exp: 5.minutes.from_now.to_i }, connect_secret, 'HS256')
  end
  let(:pathors_redirect_uri) { "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{account.id}/settings/integrations/pathors" }

  describe 'GET /pathors/callback' do
    let(:access_token) { "pat_#{SecureRandom.hex(10)}" }
    let(:refresh_token) { "prt_#{SecureRandom.hex(10)}" }
    let(:response_body) do
      {
        'access_token' => access_token,
        'refresh_token' => refresh_token,
        'token_type' => 'Bearer',
        'expires_in' => 3600,
        'scope' => 'chatwoot:connect',
        'organization_id' => 'org-uuid-1'
      }
    end

    before do
      stub_const('ENV', ENV.to_hash.merge('FRONTEND_URL' => 'http://www.example.com'))
      allow(GlobalConfigService).to receive(:load).and_call_original
      allow(GlobalConfigService).to receive(:load).with('PATHORS_CONNECT_STATE_SECRET', nil).and_return(connect_secret)
      allow(GlobalConfigService).to receive(:load).with('PATHORS_OAUTH_CLIENT_ID', nil).and_return('test_client_id')
      allow(GlobalConfigService).to receive(:load).with('PATHORS_OAUTH_CLIENT_SECRET', nil).and_return('test_client_secret')
      allow(GlobalConfigService).to receive(:load).with('PATHORS_API_URL', 'https://api.pathors.com').and_return('https://api.pathors.test')
    end

    context 'when successful' do
      before do
        stub_request(:post, 'https://api.pathors.test/oauth/token')
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'creates a pathors hook carrying the organization binding', :aggregate_failures do
        expect do
          get pathors_callback_path, params: { code: code, state: state }
        end.to change(Integrations::Hook, :count).by(1)

        hook = Integrations::Hook.last
        expect(hook.app_id).to eq('pathors')
        expect(hook.access_token).to eq(access_token)
        expect(hook.status).to eq('enabled')
        expect(hook.settings['organization_id']).to eq('org-uuid-1')
        expect(hook.settings['refresh_token']).to eq(refresh_token)
        expect(hook.settings['expires_on']).to be_present
        expect(response).to redirect_to(pathors_redirect_uri)
      end

      it 'updates the existing hook on reconnect instead of adding a second one', :aggregate_failures do
        create(:integrations_hook, account: account, app_id: 'pathors', access_token: 'old-token',
                                   settings: { organization_id: 'org-uuid-0' })

        expect do
          get pathors_callback_path, params: { code: code, state: state }
        end.not_to change(Integrations::Hook, :count)

        expect(Integrations::Hook.find_by(account: account, app_id: 'pathors').access_token).to eq(access_token)
      end
    end

    context 'when the response still carries a project instead of an organization' do
      let(:response_body) do
        {
          'access_token' => access_token,
          'refresh_token' => refresh_token,
          'token_type' => 'Bearer',
          'expires_in' => 3600,
          'scope' => 'chatwoot:connect',
          'project_id' => 'project-uuid-1'
        }
      end

      before do
        stub_request(:post, 'https://api.pathors.test/oauth/token')
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'files the project binding instead', :aggregate_failures do
        get pathors_callback_path, params: { code: code, state: state }

        hook = Integrations::Hook.find_by(account: account, app_id: 'pathors')
        expect(hook.settings['project_id']).to eq('project-uuid-1')
        expect(hook.settings).not_to have_key('organization_id')
        expect(response).to redirect_to(pathors_redirect_uri)
      end
    end

    context 'when the code is missing' do
      it 'redirects without creating a hook' do
        expect do
          get pathors_callback_path, params: { state: state }
        end.not_to change(Integrations::Hook, :count)

        expect(response).to redirect_to(pathors_redirect_uri)
      end
    end

    context 'when the state is tampered with' do
      it 'falls back to the base url without touching any account' do
        forged = JWT.encode({ account_id: account.id, iat: Time.current.to_i }, 'wrong-secret', 'HS256')

        expect do
          get pathors_callback_path, params: { code: code, state: forged }
        end.not_to change(Integrations::Hook, :count)

        expect(response).to redirect_to('http://www.example.com')
      end
    end

    context 'when the token exchange fails' do
      before do
        stub_request(:post, 'https://api.pathors.test/oauth/token')
          .to_return(status: 400, body: { error: 'invalid_grant' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'redirects back to the integration page without a hook' do
        expect do
          get pathors_callback_path, params: { code: code, state: state }
        end.not_to change(Integrations::Hook, :count)

        expect(response).to redirect_to(pathors_redirect_uri)
      end
    end
  end
end
