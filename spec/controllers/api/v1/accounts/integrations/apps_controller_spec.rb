require 'rails_helper'

RSpec.describe 'Integration Apps API', type: :request do
  let(:account) { create(:account) }

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

    end
  end

  describe 'GET /api/v1/integrations/apps/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get api_v1_account_integrations_app_url(account_id: account.id, id: 'dialogflow')
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'returns details of the app' do
        get api_v1_account_integrations_app_url(account_id: account.id, id: 'dialogflow'),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        app = response.parsed_body
        expect(app['id']).to eql('dialogflow')
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
