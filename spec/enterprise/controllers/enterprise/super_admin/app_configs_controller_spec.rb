require 'rails_helper'

RSpec.describe 'Enterprise Super Admin Application Config API', type: :request do
  let(:super_admin) { create(:super_admin) }

  before do
    allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')
    sign_in(super_admin, scope: :super_admin)
  end

  it 'renders the Enterprise-owned Shopify app handle configuration' do
    get '/super_admin/app_config?config=shopify'

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Shopify App Handle')
    expect(response.body).to include('The app handle used in Shopify Admin App Pricing URLs')
  end

  it 'saves the Enterprise-owned Shopify app handle configuration' do
    post '/super_admin/app_config?config=shopify',
         params: { app_config: { SHOPIFY_APP_HANDLE: 'chatwoot' } }

    expect(response).to redirect_to(super_admin_settings_path)
    expect(GlobalConfig.get('SHOPIFY_APP_HANDLE')['SHOPIFY_APP_HANDLE']).to eq('chatwoot')
  end

  it 'rejects an invalid Shopify app handle configuration' do
    expect do
      post '/super_admin/app_config?config=shopify',
           params: { app_config: { SHOPIFY_APP_HANDLE: 'Chatwoot App' } }
    end.not_to(change { InstallationConfig.find_by(name: 'SHOPIFY_APP_HANDLE')&.value })

    expect(response).to redirect_to(super_admin_app_config_path(config: 'shopify'))
    expect(flash[:alert]).to include('SHOPIFY_APP_HANDLE must contain only lowercase letters, numbers, and hyphens')
  end
end
