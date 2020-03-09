require 'rails_helper'

RSpec.describe 'API Base', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }

  describe 'request with api_access_token for user' do
    context 'when it is an invalid api_access_token' do
      it 'returns unauthorized' do
        get '/api/v1/profile',
            headers: { api_access_token: 'invalid' },
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is a valid api_access_token' do
      let!(:account) { create(:account) }
      let!(:user) { create(:user, account: account) }

      it 'returns current user information' do
        get '/api/v1/profile',
            headers: { api_access_token: user.access_token.token },
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(user.id)
        expect(json_response['email']).to eq(user.email)
      end
    end
  end
end
