require 'rails_helper'

RSpec.describe 'Platform Accounts API', type: :request do
  describe 'GET /platform/api/v1/accounts' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        get '/platform/api/v1/accounts'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let!(:account) { create(:account) }

      it 'shows the list of accounts' do
        get '/platform/api/v1/accounts'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('New account')
        expect(response.body).to include(account.name)
      end
    end
  end
end
