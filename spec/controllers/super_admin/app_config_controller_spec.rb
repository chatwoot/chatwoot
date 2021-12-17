require 'rails_helper'

RSpec.describe 'Super Admin Application Config API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/app_config' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/app_config'
        byebug
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      let(:config) { create(:app_config, { name: 'FB_APP_ID', value: 'TESTVALUE' }) }

      it 'shows the app_config page' do
        sign_in super_admin
        get '/super_admin/app_config'
        byebug
        expect(response).to have_http_status(:success)
        expect(response.body).to include(config.name)
      end
    end
  end
end
