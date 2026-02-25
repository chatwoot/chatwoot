require 'rails_helper'

RSpec.describe 'Token Validation API', type: :request do
  describe 'GET /validate_token' do
    let(:account) { create(:account) }

    context 'when it is an invalid token' do
      it 'returns unauthorized' do
        get '/auth/validate_token'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is a valid token' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all the labels for the conversation' do
        get '/auth/validate_token',
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(response.body).to include('payload')
      end
    end
  end
end
