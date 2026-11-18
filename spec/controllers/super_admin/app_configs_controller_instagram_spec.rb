require 'rails_helper'

RSpec.describe SuperAdmin::AppConfigsController, type: :request do
  let(:super_admin) { create(:super_admin) }
  let(:path) { '/super_admin/app_config?config=instagram' }

  it 'defaults to Instagram Login and disables the Unified Login credentials' do
    InstallationConfig.create!(name: 'INSTAGRAM_CONFIGURATION_ID', value: 'config1')
    sign_in(super_admin, scope: :super_admin)
    get path

    document = Nokogiri::HTML(response.body)
    expect(document.at_css('#app_config_INSTAGRAM_LOGIN_METHOD option[selected]')['value']).to eq('instagram_login')
    expect(document.at_css('[data-instagram-login-method="instagram_login"] fieldset')['disabled']).to be_nil
    expect(document.at_css('[data-instagram-login-method="unified_login"] fieldset')['disabled']).not_to be_nil
  end

  it 'preserves credentials when switching between login methods' do
    InstallationConfig.create!(name: 'INSTAGRAM_APP_SECRET', value: 'legacy-secret')
    InstallationConfig.create!(name: 'INSTAGRAM_UNIFIED_APP_SECRET', value: 'meta-secret')
    InstallationConfig.create!(name: 'INSTAGRAM_CONFIGURATION_ID', value: 'config1')
    sign_in(super_admin, scope: :super_admin)

    %w[instagram_login unified_login instagram_login].each do |login_method|
      post path, params: { app_config: { INSTAGRAM_LOGIN_METHOD: login_method } }
      expect(GlobalConfigService.load('INSTAGRAM_LOGIN_METHOD', nil)).to eq(login_method)
      expect(InstallationConfig.find_by!(name: 'INSTAGRAM_APP_SECRET').value).to eq('legacy-secret')
      expect(InstallationConfig.find_by!(name: 'INSTAGRAM_UNIFIED_APP_SECRET').value).to eq('meta-secret')
      expect(InstallationConfig.find_by!(name: 'INSTAGRAM_CONFIGURATION_ID').value).to eq('config1')
    end
  end

  it 'saves Unified Login credentials separately from Instagram Login credentials' do
    InstallationConfig.create!(name: 'INSTAGRAM_APP_SECRET', value: 'legacy-secret')
    sign_in(super_admin, scope: :super_admin)
    post path, params: { app_config: { INSTAGRAM_UNIFIED_APP_ID: 'meta-app', INSTAGRAM_UNIFIED_APP_SECRET: 'meta-secret',
                                       INSTAGRAM_CONFIGURATION_ID: 'config1' } }

    expect(response).to have_http_status(:redirect)
    expect(InstallationConfig.find_by!(name: 'INSTAGRAM_APP_SECRET').value).to eq('legacy-secret')
    expect(GlobalConfigService.load('INSTAGRAM_UNIFIED_APP_ID', nil)).to eq('meta-app')
    expect(GlobalConfigService.load('INSTAGRAM_UNIFIED_APP_SECRET', nil)).to eq('meta-secret')
    expect(GlobalConfigService.load('INSTAGRAM_CONFIGURATION_ID', nil)).to eq('config1')
  end

  it 'saves separate optional app names and preserves them when switching login methods' do
    sign_in(super_admin, scope: :super_admin)
    post path, params: { app_config: { INSTAGRAM_LOGIN_METHOD: 'instagram_login', INSTAGRAM_APP_NAME: 'Legacy app' } }
    post path, params: { app_config: { INSTAGRAM_LOGIN_METHOD: 'unified_login', INSTAGRAM_UNIFIED_APP_NAME: 'Unified app' } }
    get path

    document = Nokogiri::HTML(response.body)
    legacy_name = document.at_css('#app_config_INSTAGRAM_APP_NAME')
    unified_name = document.at_css('#app_config_INSTAGRAM_UNIFIED_APP_NAME')
    expect(legacy_name['value']).to eq('Legacy app')
    expect(unified_name['value']).to eq('Unified app')
    expect(legacy_name.ancestors('fieldset').first['disabled']).not_to be_nil
    expect(unified_name.ancestors('fieldset').first['disabled']).to be_nil

    post path, params: { app_config: { INSTAGRAM_LOGIN_METHOD: 'instagram_login' } }
    expect(InstallationConfig.find_by!(name: 'INSTAGRAM_APP_NAME').value).to eq('Legacy app')
    expect(InstallationConfig.find_by!(name: 'INSTAGRAM_UNIFIED_APP_NAME').value).to eq('Unified app')
  end

  it 'allows either app name to be left blank' do
    sign_in(super_admin, scope: :super_admin)
    post path, params: { app_config: { INSTAGRAM_APP_NAME: '', INSTAGRAM_UNIFIED_APP_NAME: '' } }

    expect(response).to redirect_to(path)
    expect(flash[:alert]).to be_nil
    expect(InstallationConfig.find_by!(name: 'INSTAGRAM_APP_NAME').value).to eq('')
    expect(InstallationConfig.find_by!(name: 'INSTAGRAM_UNIFIED_APP_NAME').value).to eq('')
  end
end
