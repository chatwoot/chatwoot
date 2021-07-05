require 'rails_helper'

RSpec.describe 'Super Admin platform app API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/platform_apps' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/platform_apps'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      let!(:platform_app) { create(:platform_app) }

      it 'shows the list of users' do
        sign_in super_admin
        get '/super_admin/platform_apps'
        expect(response).to have_http_status(:success)
        expect(response.body).to include(platform_app.name)
      end
    end
  end
end
