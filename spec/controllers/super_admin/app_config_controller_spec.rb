require 'rails_helper'

RSpec.describe 'Super Admin Application Config API', type: :request do
  let(:super_admin) { create(:super_admin) }
  let(:account) { create(:account) }

  describe 'GET /super_admin/app_config' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/app_config'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      let!(:config) do
        InstallationConfig.where(name: 'FB_APP_ID').first_or_initialize.tap do |installation_config|
          installation_config.value = 'TESTVALUE'
          installation_config.locked = false
          installation_config.save!
        end
      end

      it 'shows the app_config page' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/app_config?config=facebook'
        expect(response).to have_http_status(:success)
        expect(response.body).to include(config.value)
      end

      it 'shows email template customization under custom branding' do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')

        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/app_config?config=custom_branding'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Email templates')
        expect(response.body).to include('Customize the notification email layout for this brand')
        expect(response.body).to include('Manage')
        expect(response.body).not_to include('Shape the brand customers see across Chatwoot and email')
        expect(response.body).to include('/super_admin/email_layout/edit')
      end

      it 'shows email template customization on account details' do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')

        sign_in(super_admin, scope: :super_admin)
        get "/super_admin/accounts/#{account.id}"

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Account Email Templates')
        expect(response.body).to include('Customize account email templates')
        expect(response.body).to include(edit_super_admin_account_email_layout_path(account))
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

        config = GlobalConfig.get('FB_APP_ID')
        expect(config['FB_APP_ID']).to eq('FB_APP_ID')
      end
    end
  end
end
