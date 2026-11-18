require 'rails_helper'

RSpec.describe 'Super Admin branding settings', type: :request do
  let(:super_admin) { create(:super_admin) }

  before do
    ConfigLoader.new.process
    sign_in(super_admin, scope: :super_admin)
  end

  context 'without enterprise/' do
    before { allow(ChatwootApp).to receive(:enterprise?).and_return(false) }

    it 'offers the page in the settings and lists the brand keys with their values' do
      InstallationConfig.find_by!(name: 'BRAND_NAME').update!(value: 'Acme')

      get '/super_admin/app_config?config=branding'

      expect(response).to have_http_status(:success)
      expect(response.body).to include(super_admin_app_config_path(config: 'branding'))
      expect(response.body).to include('Acme')
      expect(response.body).to include(I18n.t('super_admin.app_configs.fields.LOGO_DARK.title'))
      expect(response.body).to include('app_config[DISPLAY_MANIFEST]')
    end

    it 'saves what the operator enters, which is what the installation then shows' do
      post '/super_admin/app_config?config=branding',
           params: { app_config: { BRAND_NAME: 'Acme', LOGO: 'https://acme.test/logo.svg', BRAND_COLOR: '#123abc' } }

      expect(response).to redirect_to(super_admin_app_config_path(config: 'branding'))
      expect(flash[:alert]).to be_blank
      expect(GlobalConfig.get('BRAND_NAME', 'LOGO', 'BRAND_COLOR'))
        .to eq('BRAND_NAME' => 'Acme', 'LOGO' => 'https://acme.test/logo.svg', 'BRAND_COLOR' => '#123abc')
      # What tells `branding:update` that the brand is the operator's now.
      expect(InstallationConfig.find_by!(name: 'BRANDING_EDITED_IN_SUPER_ADMIN').value).to be(true)
    end

    # The colour goes straight into the emails' CSS and the manifest.
    it 'refuses a brand color that is not a hex color, and saves nothing from the form' do
      post '/super_admin/app_config?config=branding', params: { app_config: { BRAND_NAME: 'Acme', BRAND_COLOR: 'red;}' } }

      expect(flash[:alert]).to eq(I18n.t('super_admin.app_configs.branding.invalid_color'))
      expect(InstallationConfig.find_by!(name: 'BRAND_NAME').value).to eq('Chatwoot')
      expect(InstallationConfig.find_by!(name: 'BRAND_COLOR').value).to eq('#1f93ff')
      expect(InstallationConfig.find_by(name: 'BRANDING_EDITED_IN_SUPER_ADMIN')).to be_nil
    end
  end

  # Enterprise has its own page for these keys, and puts them back to the defaults on its
  # community plan, so a second page here would save values that do not last. The settings page
  # calls Enterprise's own ChatwootHub methods, so this needs the tree loaded, not just the flag:
  # the CE workflow deletes enterprise/ before the suite.
  context 'with enterprise/' do
    before do
      skip 'needs enterprise/ loaded' unless Rails.root.join('enterprise').exist?
      allow(ChatwootApp).to receive(:enterprise?).and_return(true)
    end

    it 'does not offer the page, and does not save brand keys through it' do
      get '/super_admin/settings'
      expect(response.body).not_to include(super_admin_app_config_path(config: 'branding'))

      post '/super_admin/app_config?config=branding', params: { app_config: { BRAND_NAME: 'Acme' } }
      expect(InstallationConfig.find_by!(name: 'BRAND_NAME').value).to eq('Chatwoot')
    end
  end
end
