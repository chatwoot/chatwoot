require 'rails_helper'

RSpec.describe 'Super Admin Users API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/users' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/users'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      let!(:user) { create(:user) }

      it 'shows the list of users' do
        sign_in super_admin
        get '/super_admin/users'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('New user')
        expect(response.body).to include(CGI.escapeHTML(user.name))
      end
    end
  end
end
