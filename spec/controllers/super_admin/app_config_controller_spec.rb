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

      it 'renders failed email retries after the internal settings form' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/app_config?config=internal'

        document = Nokogiri::HTML(response.body)
        settings_form = document.css('form').find { |form| form['action'].include?('/super_admin/app_config?config=internal') }
        retry_section = document.at_css('#failed-email-retry-section')

        expect(retry_section).to be_present
        expect(settings_form.at_css('#failed-email-retry-section')).to be_nil
        expect(settings_form.xpath('following::section[@id="failed-email-retry-section"]').first).to eq(retry_section)
      end

      it 'does not render failed email retries for the email config category' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/app_config?config=email'

        expect(response.body).not_to include('failed-email-retry-section')
      end

      it 'previews failed email retry counts for a supported lookback period' do
        account = create(:account)
        inbox = create(:channel_email, account: account).inbox
        create(
          :message,
          account: account,
          inbox: inbox,
          conversation: create(:conversation, account: account, inbox: inbox),
          status: :failed,
          message_type: :outgoing
        )
        sign_in(super_admin, scope: :super_admin)

        get '/super_admin/app_config?config=internal&lookback_hours=1'

        expect(response.body).to include(I18n.t('super_admin.failed_email_retries.failed_messages'))
        expect(response.body).to include(I18n.t('super_admin.failed_email_retries.schedule_sending'))
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
    end
  end
end
