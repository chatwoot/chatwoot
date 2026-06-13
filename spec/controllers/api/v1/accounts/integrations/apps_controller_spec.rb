require 'rails_helper'

RSpec.describe 'Integration Apps API', type: :request do
  let(:account) { create(:account) }

  before { allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(true) }

  describe 'GET /api/v1/integrations/apps' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get api_v1_account_integrations_apps_url(account)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'returns all active apps without sensitive information if the user is an agent' do
        first_app = Integrations::App.all.find { |app| app.active?(account) }
        get api_v1_account_integrations_apps_url(account),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        apps = response.parsed_body['payload'].first
        expect(apps['id']).to eql(first_app.id)
        expect(apps['name']).to eql(first_app.name)
        expect(apps['action']).to be_nil
      end

      it 'will not return sensitive information for openai app for agents' do
        openai = create(:integrations_hook, :openai, account: account)
        get api_v1_account_integrations_apps_url(account),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        app = response.parsed_body['payload'].find { |int_app| int_app['id'] == openai.app.id }
        expect(app['hooks'].first['settings']).to be_nil
      end

      it 'returns all active apps with admin metadata if user is an admin' do
        first_app = Integrations::App.all.find { |app| app.active?(account) }
        get api_v1_account_integrations_apps_url(account),
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        apps = response.parsed_body['payload'].first
        expect(apps['id']).to eql(first_app.id)
        expect(apps['name']).to eql(first_app.name)
        expect(apps['action']).to eql(first_app.action)
      end

      it 'returns slack app with appropriate redirect url when configured' do
        allow(GlobalConfigService).to receive(:load).and_call_original
        allow(GlobalConfigService).to receive(:load).with('SLACK_CLIENT_ID', nil).and_return('client_id')
        allow(GlobalConfigService).to receive(:load).with('SLACK_CLIENT_SECRET', nil).and_return('client_secret')

        get api_v1_account_integrations_apps_url(account),
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        apps = response.parsed_body['payload']
        slack_app = apps.find { |app| app['id'] == 'slack' }
        expect(slack_app['action']).to include('client_id=client_id')
      end

      it 'returns visible hook settings for openai app for admins' do
        openai = create(:integrations_hook, :openai, account: account)
        get api_v1_account_integrations_apps_url(account),
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        app = response.parsed_body['payload'].find { |int_app| int_app['id'] == openai.app.id }
        expect(app['hooks'].first['settings']).not_to be_nil
      end

      it 'redacts secrets and only returns visible settings for openai hooks' do
        openai = create(
          :integrations_hook,
          :openai,
          account: account,
          settings: { api_key: 'sk-secret', label_suggestion: true }
        )
        get api_v1_account_integrations_apps_url(account),
            headers: admin.create_new_auth_token,
            as: :json

        app = response.parsed_body['payload'].find { |int_app| int_app['id'] == openai.app.id }
        expect(app['hooks'].first['settings']).to eq('label_suggestion' => true)
      end

      it 'keeps slack channel display settings while redacting unspecified settings' do
        create(:integrations_hook, account: account, settings: { channel_name: 'support', signing_secret: 'secret' })
        allow(GlobalConfigService).to receive(:load).and_call_original
        allow(GlobalConfigService).to receive(:load).with('SLACK_CLIENT_SECRET', nil).and_return('client_secret')

        get api_v1_account_integrations_apps_url(account),
            headers: admin.create_new_auth_token,
            as: :json

        app = response.parsed_body['payload'].find { |int_app| int_app['id'] == 'slack' }
        expect(app['hooks'].first['settings']).to eq('channel_name' => 'support')
      end
    end
  end

  describe 'GET /api/v1/integrations/apps/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get api_v1_account_integrations_app_url(account_id: account.id, id: 'slack')
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'returns details of the app' do
        get api_v1_account_integrations_app_url(account_id: account.id, id: 'slack'),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        app = response.parsed_body
        expect(app['id']).to eql('slack')
        expect(app['name']).to eql('Slack')
      end

      it 'will not return sensitive information for openai app for agents' do
        openai = create(:integrations_hook, :openai, account: account)
        get api_v1_account_integrations_app_url(account_id: account.id, id: openai.app.id),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        app = response.parsed_body
        expect(app['hooks'].first['settings']).to be_nil
      end

      it 'returns visible hook settings for openai app for admins' do
        openai = create(:integrations_hook, :openai, account: account)
        get api_v1_account_integrations_app_url(account_id: account.id, id: openai.app.id),
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        app = response.parsed_body
        expect(app['hooks'].first['settings']).not_to be_nil
      end

      it 'hides credentials and keeps visible settings for google credential integrations' do
        hook = create(:integrations_hook, :google_translate, account: account,
                                                             settings: { project_id: 'project-1',
                                                                         credentials: { private_key: 'secret' } })
        get api_v1_account_integrations_app_url(account_id: account.id, id: hook.app.id),
            headers: admin.create_new_auth_token,
            as: :json

        app = response.parsed_body
        expect(app['hooks'].first['settings']).to eq('project_id' => 'project-1')
      end

      it 'returns empty settings for oauth integrations with no visible properties' do
        hook = create(
          :integrations_hook,
          :linear,
          account: account,
          settings: { token_type: 'Bearer', refresh_token: 'refresh-secret', expires_in: 7200 }
        )
        get api_v1_account_integrations_app_url(account_id: account.id, id: hook.app.id),
            headers: admin.create_new_auth_token,
            as: :json

        app = response.parsed_body
        expect(app['hooks'].first['settings']).to eq({})
      end

      it 'does not expose leadsquared credential keys in visible settings' do
        account.enable_features('crm_integration')
        hook = create(:integrations_hook, :leadsquared, account: account,
                                                        settings: {
                                                          'access_key' => 'access-secret',
                                                          'secret_key' => 'secret',
                                                          'endpoint_url' => 'https://api.leadsquared.com/',
                                                          'enable_conversation_activity' => true
                                                        })
        get api_v1_account_integrations_app_url(account_id: account.id, id: hook.app.id),
            headers: admin.create_new_auth_token,
            as: :json

        settings = response.parsed_body['hooks'].first['settings']
        expect(settings).to eq(
          'endpoint_url' => 'https://api.leadsquared.com/',
          'enable_conversation_activity' => true
        )
      end
    end
  end
end
