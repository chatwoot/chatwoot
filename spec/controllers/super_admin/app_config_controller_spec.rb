require 'rails_helper'

RSpec.describe 'Super Admin Application Config API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/app_config' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/app_config'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      let!(:config) { create(:installation_config, { name: 'FB_APP_ID', value: 'TESTVALUE' }) }

      it 'shows the app_config page' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/app_config?config=facebook'
        expect(response).to have_http_status(:success)
        expect(response.body).to include(config.value)
      end
    end
  end

  describe 'POST /super_admin/app_config' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        post '/super_admin/app_config', params: { app_config: { TESTKEY: 'TESTVALUE' } }
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an aunthenticated super admin' do
      it 'shows the app_config page' do
        sign_in(super_admin, scope: :super_admin)
        post '/super_admin/app_config?config=facebook', params: { app_config: { FB_APP_ID: 'FB_APP_ID' } }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(super_admin_settings_path)
        expect(flash[:notice]).to be_present
        expect(flash[:alert]).to be_blank
        expect(flash[:success]).to be_blank

        config = GlobalConfig.get('FB_APP_ID')
        expect(config['FB_APP_ID']).to eq('FB_APP_ID')
      end

      it 'asks admins to restart web and worker processes for runtime config changes' do
        sign_in(super_admin, scope: :super_admin)
        post '/super_admin/app_config?config=captain', params: { app_config: { CAPTAIN_OPEN_AI_ENDPOINT: 'https://api.openai.com' } }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(super_admin_settings_path)
        expect(flash[:success]).to be_present
        expect(flash[:alert]).to be_blank
        expect(flash[:notice]).to be_blank
      end

      it 'rejects invalid Shopify Partner configuration before persisting any submitted value' do
        create(:installation_config, name: 'SHOPIFY_PARTNER_ORGANIZATION_ID', value: '123', locked: false)
        sign_in(super_admin, scope: :super_admin)

        post '/super_admin/app_config?config=shopify',
             params: {
               app_config: {
                 SHOPIFY_PARTNER_ORGANIZATION_ID: 'not-numeric',
                 SHOPIFY_PARTNER_APP_ID: 'gid://shopify/App/456',
                 SHOPIFY_PARTNER_ACCESS_TOKEN: 'partner-token',
                 SHOPIFY_PARTNER_API_VERSION: '2026-07'
               }
             }

        expect(response).to redirect_to(super_admin_app_config_path(config: 'shopify'))
        expect(flash[:alert]).to eq('SHOPIFY_PARTNER_ORGANIZATION_ID must be numeric')
        expect(GlobalConfig.get('SHOPIFY_PARTNER_ORGANIZATION_ID')['SHOPIFY_PARTNER_ORGANIZATION_ID']).to eq('123')
        expect(GlobalConfig.get('SHOPIFY_PARTNER_APP_ID')['SHOPIFY_PARTNER_APP_ID']).to be_nil
      end

      it 'validates a partial Shopify Partner update against the saved configuration' do
        {
          'SHOPIFY_PARTNER_ORGANIZATION_ID' => '123',
          'SHOPIFY_PARTNER_APP_ID' => 'gid://shopify/App/456',
          'SHOPIFY_PARTNER_ACCESS_TOKEN' => 'partner-token',
          'SHOPIFY_PARTNER_API_VERSION' => '2026-07'
        }.each do |name, value|
          create(:installation_config, name: name, value: value, locked: false)
        end
        sign_in(super_admin, scope: :super_admin)

        post '/super_admin/app_config?config=shopify',
             params: { app_config: { SHOPIFY_PARTNER_API_VERSION: '2026-10' } }

        expect(response).to redirect_to(super_admin_settings_path)
        expect(flash[:alert]).to be_blank
        expect(GlobalConfig.get('SHOPIFY_PARTNER_API_VERSION')['SHOPIFY_PARTNER_API_VERSION']).to eq('2026-10')
      end
    end
  end
end
