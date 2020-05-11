require 'rails_helper'

RSpec.describe 'Super Admin super admins API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/users' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/super_admins'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      it 'shows the list of super admins' do
        sign_in super_admin
        get '/super_admin/super_admins'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('New super admin')
        expect(response.body).to include(super_admin.email)
      end
    end
  end
end
