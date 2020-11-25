require 'rails_helper'

RSpec.describe 'Platform Account Users API', type: :request do
  let!(:account) { create(:account) }

  describe 'GET /platform/api/v1/accounts/{account_id}/account_users' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        get "/platform/api/v1/accounts/#{account.id}/account_users"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
