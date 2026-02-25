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

      it 'will not return sensitive information for openai app for agents' do
        openai = create(:integrations_hook, :openai, account: account)
        get api_v1_account_integrations_apps_url(account),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        app = response.parsed_body['payload'].find { |int_app| int_app['id'] == openai.app.id }
        expect(app['hooks'].first['settings']).to be_nil
      end

      it 'returns all active apps with sensitive information if user is an admin' do
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
        with_modified_env SLACK_CLIENT_ID: 'client_id', SLACK_CLIENT_SECRET: 'client_secret' do
          get api_v1_account_integrations_apps_url(account),
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          apps = response.parsed_body['payload']
          slack_app = apps.find { |app| app['id'] == 'slack' }
          expect(slack_app['action']).to include('client_id=client_id')
        end
      end

      it 'will return sensitive information for openai app for admins' do
        openai = create(:integrations_hook, :openai, account: account)
        get api_v1_account_integrations_apps_url(account),
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        app = response.parsed_body['payload'].find { |int_app| int_app['id'] == openai.app.id }
        expect(app['hooks'].first['settings']).not_to be_nil
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

      it 'will return sensitive information for openai app for admins' do
        openai = create(:integrations_hook, :openai, account: account)
        get api_v1_account_integrations_app_url(account_id: account.id, id: openai.app.id),
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        app = response.parsed_body
        expect(app['hooks'].first['settings']).not_to be_nil
      end
    end
  end
end
