require 'rails_helper'

RSpec.describe Github::CallbacksController do
  let(:account) { create(:account) }
  let(:signed_account_id) { account.to_signed_global_id(expires_in: 1.hour) }

  before do
    allow(GlobalConfigService).to receive(:load).with('GITHUB_CLIENT_ID', nil).and_return('test_client_id')
    allow(GlobalConfigService).to receive(:load).with('GITHUB_CLIENT_SECRET', nil).and_return('test_client_secret')

    # Configure test environment
    @original_frontend_url = ENV.fetch('FRONTEND_URL', nil)
    ENV['FRONTEND_URL'] = 'http://localhost:3000'

    # Configure request.host to match our test URL
    allow_any_instance_of(ActionDispatch::Request).to receive(:host).and_return('localhost')
    allow_any_instance_of(ActionDispatch::Request).to receive(:port).and_return(3000)
    allow_any_instance_of(ActionDispatch::Request).to receive(:protocol).and_return('http://')

    # Mock all GitHub OAuth API calls to prevent WebMock errors
    stub_request(:post, 'https://github.com/login/oauth/access_token')
      .to_return(status: 200, body: '', headers: {})
  end

  after do
    ENV['FRONTEND_URL'] = @original_frontend_url
  end

  describe 'GET #show' do
    context 'when handling installation with OAuth (both installation_id and code present)' do
      let(:oauth_response) do
        double('OAuth2::Response', response: double(parsed: {
                                                      'access_token' => 'test_token',
                                                      'token_type' => 'bearer',
                                                      'scope' => 'repo,read:org'
                                                    }))
      end

      before do
        oauth_client = double('OAuth2::Client')
        auth_code = double('OAuth2::Strategy::AuthCode')
        allow(controller).to receive(:oauth_client).and_return(oauth_client)
        allow(oauth_client).to receive(:auth_code).and_return(auth_code)
        allow(auth_code).to receive(:get_token).and_return(oauth_response)
      end

      it 'creates integration hook with installation_id and redirects' do
        get :show, params: {
          code: 'test_code',
          installation_id: '12345',
          setup_action: 'install',
          state: signed_account_id
        }

        hook = account.hooks.find_by(app_id: 'github')
        expect(hook).to be_present
        expect(hook.access_token).to eq('test_token')
        expect(hook.settings['installation_id']).to eq('12345')
        expect(hook.settings['token_type']).to eq('bearer')
        expect(hook.settings['scope']).to eq('repo,read:org')
        expect(response).to redirect_to(a_string_including('/settings/integrations/github'))
      end
    end

    context 'when handling installation only (only installation_id present)' do
      it 'redirects to OAuth URL' do
        get :show, params: {
          installation_id: '12345',
          setup_action: 'install',
          state: signed_account_id
        }

        expect(response).to be_redirect
        expect(response.location).to include('github?setup_action=install&installation_id=12345')
      end
    end

    context 'when handling authorization only (only code present)' do
      let(:oauth_response) do
        double('OAuth2::Response', response: double(parsed: {
                                                      'access_token' => 'test_token',
                                                      'token_type' => 'bearer',
                                                      'scope' => 'repo,read:org'
                                                    }))
      end

      before do
        oauth_client = double('OAuth2::Client')
        auth_code = double('OAuth2::Strategy::AuthCode')
        allow(controller).to receive(:oauth_client).and_return(oauth_client)
        allow(oauth_client).to receive(:auth_code).and_return(auth_code)
        allow(auth_code).to receive(:get_token).and_return(oauth_response)
      end

      it 'creates integration hook without installation_id and redirects' do
        get :show, params: {
          code: 'test_code',
          state: signed_account_id
        }

        hook = account.hooks.find_by(app_id: 'github')
        expect(hook).to be_present
        expect(hook.access_token).to eq('test_token')
        expect(hook.settings['installation_id']).to be_nil
        expect(response).to redirect_to(a_string_including('/settings/integrations/github'))
      end
    end

    context 'when state parameter is missing' do
      it 'handles error gracefully and redirects to fallback URI' do
        get :show, params: {
          code: 'test_code',
          installation_id: '12345',
          setup_action: 'install'
        }

        expect(response).to be_redirect
      end
    end

    context 'when state parameter is invalid' do
      it 'handles error gracefully and redirects to fallback URI' do
        get :show, params: {
          code: 'test_code',
          installation_id: '12345',
          setup_action: 'install',
          state: 'invalid_state'
        }

        expect(response).to be_redirect
      end
    end

    context 'when OAuth fails' do
      before do
        oauth_client = double('OAuth2::Client')
        auth_code = double('OAuth2::Strategy::AuthCode')
        allow(controller).to receive(:oauth_client).and_return(oauth_client)
        allow(oauth_client).to receive(:auth_code).and_return(auth_code)
        allow(auth_code).to receive(:get_token).and_raise(StandardError, 'OAuth failed')
      end

      it 'logs error and redirects to fallback URI' do
        expect(Rails.logger).to receive(:error).with('Github callback error: OAuth failed')

        get :show, params: {
          code: 'test_code',
          installation_id: '12345',
          setup_action: 'install',
          state: signed_account_id
        }

        expect(response).to be_redirect
      end
    end
  end

  describe 'private methods' do
    let(:controller_instance) { described_class.new }

    before do
      allow(controller_instance).to receive(:account).and_return(account)
      allow(controller_instance).to receive(:parsed_body).and_return({
                                                                       'access_token' => 'test_token',
                                                                       'token_type' => 'bearer',
                                                                       'scope' => 'repo,read:org'
                                                                     })
      # Mock session for private method tests
      allow(controller_instance).to receive(:session).and_return({})
    end

    describe '#build_hook_settings' do
      it 'builds settings with installation_id parameter' do
        settings = controller_instance.send(:build_hook_settings, '12345')

        expect(settings[:token_type]).to eq('bearer')
        expect(settings[:scope]).to eq('repo,read:org')
        expect(settings[:installation_id]).to eq('12345')
      end

      it 'builds settings without installation_id when nil' do
        settings = controller_instance.send(:build_hook_settings, nil)

        expect(settings[:token_type]).to eq('bearer')
        expect(settings[:scope]).to eq('repo,read:org')
        expect(settings.key?(:installation_id)).to be false
      end
    end

    describe '#create_integration_hook' do
      it 'creates a new hook with correct attributes' do
        settings = { token_type: 'bearer', scope: 'repo,read:org', installation_id: '12345' }
        hook = controller_instance.send(:create_integration_hook, settings)

        expect(hook.access_token).to eq('test_token')
        expect(hook.status).to eq('enabled')
        expect(hook.app_id).to eq('github')
        # Convert expected settings to string keys to match actual storage format
        expect(hook.settings).to eq(settings.stringify_keys)
        expect(hook.account).to eq(account)
      end
    end
  end
end