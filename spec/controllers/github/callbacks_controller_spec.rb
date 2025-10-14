require 'rails_helper'

RSpec.describe Github::CallbacksController, type: :controller do
  let(:account) { create(:account) }
  let(:signed_account_id) { account.to_signed_global_id(expires_in: 1.hour) }

  before do
    # Clear any existing GitHub hooks for the account
    account.hooks.where(app_id: 'github').destroy_all

    allow(GlobalConfigService).to receive(:load).with('GITHUB_CLIENT_ID', nil).and_return('test_client_id')
    allow(GlobalConfigService).to receive(:load).with('GITHUB_CLIENT_SECRET', nil).and_return('test_client_secret')
  end

  describe 'route accessibility' do
    it 'is accessible via the github callback route' do
      expect(get: '/github/callback').to route_to(
        controller: 'github/callbacks',
        action: 'show'
      )
    end
  end

  describe 'helper methods' do
    describe '#account' do
      it 'resolves account from valid signed global id' do
        controller.params = { state: signed_account_id }
        expect(controller.send(:account)).to eq(account)
      end

      it 'raises error for missing state' do
        controller.params = {}
        expect { controller.send(:account) }.to raise_error(ActionController::BadRequest, 'Invalid account context')
      end

      it 'raises error for invalid state' do
        controller.params = { state: 'invalid_state' }
        expect { controller.send(:account) }.to raise_error(ActionController::BadRequest, 'Invalid account context')
      end
    end

    describe '#oauth_client' do
      it 'creates OAuth2 client with correct configuration' do
        oauth_client = controller.send(:oauth_client)
        expect(oauth_client).to be_a(OAuth2::Client)
        expect(oauth_client.id).to eq('test_client_id')
        expect(oauth_client.secret).to eq('test_client_secret')
        expect(oauth_client.site).to eq('https://github.com')
        expect(oauth_client.options[:token_url]).to eq('/login/oauth/access_token')
        expect(oauth_client.options[:authorize_url]).to eq('/login/oauth/authorize')
      end
    end

    describe '#github_redirect_uri' do
      before do
        allow(controller).to receive(:account).and_return(account)
      end

      it 'generates correct GitHub redirect URI' do
        with_modified_env FRONTEND_URL: 'http://localhost:3000' do
          uri = controller.send(:github_redirect_uri)
          expect(uri).to eq("http://localhost:3000/app/accounts/#{account.id}/settings/integrations/github")
        end
      end
    end

    describe '#fallback_redirect_uri' do
      it 'generates fallback redirect URI when account is unavailable' do
        allow(controller).to receive(:account).and_raise(StandardError)

        with_modified_env FRONTEND_URL: 'http://localhost:3000' do
          uri = controller.send(:fallback_redirect_uri)
          expect(uri).to eq('http://localhost:3000/app/settings/integrations')
        end
      end
    end

    describe '#build_hook_settings' do
      let(:mock_parsed_body) do
        {
          'access_token' => 'test_token',
          'token_type' => 'bearer',
          'scope' => 'repo,read:org'
        }
      end

      before do
        allow(controller).to receive(:parsed_body).and_return(mock_parsed_body)
      end

      it 'builds hook settings with installation_id' do
        settings = controller.send(:build_hook_settings, '12345')
        expect(settings).to include(
          token_type: 'bearer',
          scope: 'repo,read:org',
          installation_id: '12345'
        )
      end

      it 'builds hook settings without installation_id when nil' do
        settings = controller.send(:build_hook_settings, nil)
        expect(settings).to include(
          token_type: 'bearer',
          scope: 'repo,read:org'
        )
        expect(settings).not_to have_key(:installation_id)
      end

      it 'removes nil installation_id values' do
        settings = controller.send(:build_hook_settings, nil)
        expect(settings.keys).not_to include(:installation_id)
      end
    end

    describe '#create_integration_hook' do
      let(:settings) do
        {
          token_type: 'bearer',
          scope: 'repo,read:org',
          installation_id: '12345'
        }
      end

      before do
        allow(controller).to receive(:account).and_return(account)
        allow(controller).to receive(:parsed_body).and_return({
                                                                'access_token' => 'test_token'
                                                              })
      end

      it 'creates integration hook with correct attributes' do
        hook = controller.send(:create_integration_hook, settings)
        expect(hook.access_token).to eq('test_token')
        expect(hook.status).to eq('enabled')
        expect(hook.app_id).to eq('github')
        expect(hook.settings).to eq(settings.stringify_keys)
        expect(hook.account).to eq(account)
      end
    end

    describe '#build_oauth_url' do
      it 'builds OAuth URL with installation context' do
        with_modified_env FRONTEND_URL: 'http://localhost:3000' do
          url = controller.send(:build_oauth_url, '12345')
          expect(url).to include('github?setup_action=install&installation_id=12345')
          expect(controller.session[:github_installation_id]).to eq('12345')
        end
      end
    end

    describe '#base_url' do
      it 'returns FRONTEND_URL when set' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(controller.send(:base_url)).to eq('https://app.chatwoot.com')
        end
      end

      it 'returns default localhost when FRONTEND_URL not set' do
        with_modified_env FRONTEND_URL: nil do
          expect(controller.send(:base_url)).to eq('http://localhost:3000')
        end
      end
    end
  end
end