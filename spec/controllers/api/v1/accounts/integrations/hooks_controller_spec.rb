require 'rails_helper'

RSpec.describe 'Integration Hooks API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:params) { { app_id: 'dialogflow', inbox_id: inbox.id, settings: { project_id: 'xx', credentials: { test: 'test' } } } }

  describe 'POST /api/v1/accounts/{account.id}/integrations/hooks' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post api_v1_account_integrations_hooks_url(account_id: account.id),
             params: params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'return unauthorized if agent' do
        post api_v1_account_integrations_hooks_url(account_id: account.id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates hooks if admin' do
        post api_v1_account_integrations_hooks_url(account_id: account.id),
             params: params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data['app']['id']).to eq params[:app_id]
      end
    end
  end
end
