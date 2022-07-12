require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::MacrosController', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  before :each do
    create(:macro, account: account, created_by: administrator, updated_by: administrator)
    create(:macro, account: account, created_by: administrator, updated_by: administrator)
  end

  describe 'GET /api/v1/accounts/{account.id}/macros' do
    context 'when it is an authenticated user' do
      it 'returns all records' do
        get "/api/v1/accounts/#{account.id}/macros",
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        binding.pry
        expect(body[:payload].first[:id]).to eq(macro.id)
      end
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/macros"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/macros' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/macros"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        {
          'name': 'Add label, send message and close the chat',
          'actions': [
            {
              'action_name': :add_label,
              'action_params': %w[support priority_customer]
            },
            {
              'action_name': :send_message,
              'action_params': ['Welcome to the chatwoot platform.']
            },
            {
              'action_name': :resolved
            }
          ]
        }
      end
    end
  end
end
