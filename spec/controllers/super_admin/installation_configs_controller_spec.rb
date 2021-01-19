require 'rails_helper'

RSpec.describe 'Super Admin Installation Config API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/installation_configs/new' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/installation_configs/new'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      let(:config) { create(:installation_config, { name: 'TESTCONFIG', value: 'TESTVALUE', locked: false }) }

      before do
        config
      end

      it 'shows the installation_configs create page' do
        sign_in super_admin
        get '/super_admin/installation_configs/new'
        expect(response).to have_http_status(:success)
      end

      it 'shows the installation_configs edit page' do
        sign_in super_admin
        editable_config = InstallationConfig.editable.first
        get "/super_admin/installation_configs/#{editable_config.id}/edit"
        expect(response).to have_http_status(:success)
      end

      it 'shows the installation_configs list page' do
        sign_in super_admin
        get '/super_admin/installation_configs'
        expect(response).to have_http_status(:success)
        expect(response.body).to include(config.name)
      end
    end
  end
end
