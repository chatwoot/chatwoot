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

      it 'returns all the apps' do
        get api_v1_account_integrations_apps_url(account),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        app = JSON.parse(response.body)['payload'].first
        expect(app['id']).to eql('webhook')
        expect(app['name']).to eql('Webhooks')
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
