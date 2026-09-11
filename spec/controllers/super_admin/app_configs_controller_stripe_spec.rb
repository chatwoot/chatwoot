require 'rails_helper'

RSpec.describe SuperAdmin::AppConfigsController, type: :request do
  let(:super_admin) { create(:super_admin) }
  let(:path) { '/super_admin/app_config?config=stripe' }

  it 'requires Super Admin authentication' do
    get path
    expect(response).to have_http_status(:redirect)
  end

  it 'exposes Stripe settings with a masked secret field' do
    sign_in(super_admin, scope: :super_admin)
    get path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Stripe App Authorization URL', 'Stripe App Secret Key')
    expect(response.body).to include('type="password"')
  end

  it 'saves only the allowed Stripe installation settings' do
    sign_in(super_admin, scope: :super_admin)
    post path, params: { app_config: { STRIPE_APP_AUTHORIZE_URL: 'https://marketplace.stripe.com/oauth/test',
                                       STRIPE_APP_SECRET_KEY: 'sk_test_example', UNRELATED_SETTING: 'ignored' } }
    expect(response).to have_http_status(:redirect)
    expect(InstallationConfig.find_by!(name: 'STRIPE_APP_SECRET_KEY').value).to eq('sk_test_example')
    expect(GlobalConfig.get_value('STRIPE_APP_AUTHORIZE_URL')).to eq('https://marketplace.stripe.com/oauth/test')
    expect(InstallationConfig.exists?(name: 'UNRELATED_SETTING')).to be false
  end

  it 'rejects malformed settings without persisting either value' do
    sign_in(super_admin, scope: :super_admin)
    post path, params: { app_config: { STRIPE_APP_AUTHORIZE_URL: 'https://example.com/authorize', STRIPE_APP_SECRET_KEY: 'pk_live_example' } }
    expect(response).to redirect_to(super_admin_app_config_path(config: 'stripe'))
    expect(flash[:alert]).to include('HTTPS Stripe Marketplace URL', 'sk_test_ or sk_live_')
    expect(InstallationConfig.find_by(name: 'STRIPE_APP_SECRET_KEY')&.value).to be_blank
    expect(InstallationConfig.find_by(name: 'STRIPE_APP_AUTHORIZE_URL')&.value).to be_blank
  end
end
