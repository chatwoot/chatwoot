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
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/platform_apps'
        expect(response).to have_http_status(:success)
        expect(response.body).to include(platform_app.name)
      end
    end
  end

  describe 'DELETE /super_admin/platform_apps/:id' do
    let!(:platform_app) { create(:platform_app) }
    let(:access_token) { platform_app.access_token }

    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        delete "/super_admin/platform_apps/#{platform_app.id}", params: { _method: :delete }
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      it 'deletes the platform app' do
        sign_in(super_admin, scope: :super_admin)
        expect do
          delete "/super_admin/platform_apps/#{platform_app.id}", params: { _method: :delete }
        end.to change(PlatformApp, :count).by(-1)
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(super_admin_platform_apps_path)
      end
    end
  end
end
