require 'rails_helper'

RSpec.describe Notion::CallbacksController, type: :controller do
  let(:account) { create(:account) }
  let(:state) { account.to_sgid.to_s }
  let(:oauth_code) { 'test_oauth_code' }

  let(:mock_oauth_client) { instance_double(OAuth2::Client) }
  let(:mock_auth_code) { instance_double(OAuth2::Strategy::AuthCode) }
  let(:mock_token_response) { instance_double(OAuth2::AccessToken) }
  let(:mock_response) { instance_double(Faraday::Response) }

  let(:notion_response_body) do
    {
      'access_token' => 'notion_access_token_123',
      'token_type' => 'bearer',
      'workspace_name' => 'Test Workspace',
      'workspace_id' => 'workspace_123',
      'workspace_icon' => 'https://notion.so/icon.png',
      'bot_id' => 'bot_123',
      'owner' => {
        'type' => 'user',
        'user' => {
          'id' => 'user_123',
          'name' => 'Test User'
        }
      }
    }
  end

  before do
    allow(controller).to receive(:notion_client).and_return(mock_oauth_client)
    allow(mock_oauth_client).to receive(:auth_code).and_return(mock_auth_code)
    allow(mock_auth_code).to receive(:get_token).and_return(mock_token_response)
    allow(mock_token_response).to receive(:response).and_return(mock_response)
    allow(mock_response).to receive(:parsed).and_return(notion_response_body)
  end

  describe 'GET #show' do
    context 'when OAuth callback is successful' do
      it 'creates a new integration hook' do
        expect do
          get :show, params: { code: oauth_code, state: state }
        end.to change(Integrations::Hook, :count).by(1)
      end

      it 'sets correct hook attributes' do
        get :show, params: { code: oauth_code, state: state }

        hook = Integrations::Hook.last
        expect(hook.account).to eq(account)
        expect(hook.app_id).to eq('notion')
        expect(hook.access_token).to eq('notion_access_token_123')
        expect(hook.status).to eq('enabled')
      end

      it 'stores notion workspace data in settings' do
        get :show, params: { code: oauth_code, state: state }

        hook = Integrations::Hook.last
        expect(hook.settings['token_type']).to eq('bearer')
        expect(hook.settings['workspace_name']).to eq('Test Workspace')
        expect(hook.settings['workspace_id']).to eq('workspace_123')
        expect(hook.settings['workspace_icon']).to eq('https://notion.so/icon.png')
        expect(hook.settings['bot_id']).to eq('bot_123')
        expect(hook.settings['owner']).to eq(notion_response_body['owner'])
      end

      it 'redirects to integration settings page' do
        get :show, params: { code: oauth_code, state: state }

        expect(response).to redirect_to("#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/app/accounts/#{account.id}/settings/integrations/notion")
      end

      it 'calls the OAuth client with correct parameters' do
        expect(mock_auth_code).to receive(:get_token).with(
          oauth_code,
          redirect_uri: "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/notion/callback"
        )

        get :show, params: { code: oauth_code, state: state }
      end
    end

    context 'when hook save fails during handle_response' do
      it 'raises error and uses parent exception handling' do
        mock_hook = instance_double(Integrations::Hook)
        allow(account.hooks).to receive(:new).and_return(mock_hook)
        allow(mock_hook).to receive(:save!).and_raise(StandardError, 'Save failed')

        # Parent class handles exceptions with ChatwootExceptionTracker and redirects to '/'
        expect(ChatwootExceptionTracker).to receive(:new).and_call_original

        get :show, params: { code: oauth_code, state: state }

        expect(response).to redirect_to('/')
      end
    end
  end

  describe 'provider-specific methods' do
    describe '#provider_name' do
      it 'returns notion' do
        expect(controller.send(:provider_name)).to eq('notion')
      end
    end

    describe '#oauth_client' do
      it 'returns notion_client' do
        expect(controller.send(:oauth_client)).to eq(mock_oauth_client)
      end
    end

    describe '#notion_redirect_uri' do
      it 'returns correct redirect URI' do
        allow(controller).to receive(:account).and_return(account)
        expected_uri = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/app/accounts/#{account.id}/settings/integrations/notion"
        expect(controller.send(:notion_redirect_uri)).to eq(expected_uri)
      end
    end
  end
end