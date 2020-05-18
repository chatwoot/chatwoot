require 'rails_helper'

RSpec.describe 'Super Admin Account Users API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/account_users' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/account_users'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      let!(:account_user) { create(:account_user) }

      it 'shows the list of account users' do
        sign_in super_admin
        get '/super_admin/account_users'
        expect(response).to have_http_status(:success)
        expect(response.body).to include(account_user.account.id.to_s)
        expect(response.body).to include(account_user.user.id.to_s)
      end
    end
  end
end
