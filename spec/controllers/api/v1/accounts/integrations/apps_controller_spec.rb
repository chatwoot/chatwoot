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
      let(:agent) { create(:user, account: account, role: :administrator) }

      it 'returns all active apps' do
        first_app = Integrations::App.all.find(&:active?)
        get api_v1_account_integrations_apps_url(account),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        apps = JSON.parse(response.body)['payload'].first
        expect(apps['id']).to eql(first_app.id)
        expect(apps['name']).to eql(first_app.name)
      end

      it 'returns slack app with appropriate redirect url when configured' do
        with_modified_env SLACK_CLIENT_ID: 'client_id', SLACK_CLIENT_SECRET: 'client_secret' do
          get api_v1_account_integrations_apps_url(account),
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          apps = JSON.parse(response.body)['payload']
          slack_app = apps.find { |app| app['id'] == 'slack' }
          expect(slack_app['action']).to include('client_id=client_id')
        end
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
      let(:agent) { create(:user, account: account, role: :administrator) }

      it 'returns details of the app' do
        get api_v1_account_integrations_app_url(account_id: account.id, id: 'slack'),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        app = JSON.parse(response.body)
        expect(app['id']).to eql('slack')
        expect(app['name']).to eql('Slack')
      end
    end
  end
end
