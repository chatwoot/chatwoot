# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardController, 'Feature Flag Exposure' do
  let(:user) { create(:user) }
  let(:account) { create(:account) }

  before do
    create(:account_user, user: user, account: account)
    sign_in user
  end

  describe 'SOCIALWISE_RICH_DASHBOARD feature flag exposure' do
    context 'when feature flag is enabled globally' do
      before do
        allow(GlobalConfig).to receive(:get).and_call_original
        allow(GlobalConfig).to receive(:get).with(
          'LOGO', 'LOGO_DARK', 'LOGO_THUMBNAIL',
          'INSTALLATION_NAME',
          'WIDGET_BRAND_URL', 'TERMS_URL',
          'BRAND_URL', 'BRAND_NAME',
          'PRIVACY_URL',
          'DISPLAY_MANIFEST',
          'CREATE_NEW_ACCOUNT_FROM_DASHBOARD',
          'CHATWOOT_INBOX_TOKEN',
          'API_CHANNEL_NAME',
          'API_CHANNEL_THUMBNAIL',
          'ANALYTICS_TOKEN',
          'DIRECT_UPLOADS_ENABLED',
          'HCAPTCHA_SITE_KEY',
          'LOGOUT_REDIRECT_LINK',
          'DISABLE_USER_PROFILE_UPDATE',
          'DEPLOYMENT_ENV',
          'INSTALLATION_PRICING_PLAN',
          'SOCIALWISE_RICH_DASHBOARD'
        ).and_return({
          'SOCIALWISE_RICH_DASHBOARD' => 'true'
        }.with_indifferent_access)
      end

      it 'includes SOCIALWISE_RICH_DASHBOARD in global config' do
        get :index

        expect(response).to have_http_status(:success)
        expect(assigns(:global_config)).to include('SOCIALWISE_RICH_DASHBOARD' => 'true')
      end

      it 'makes feature flag accessible to frontend JavaScript' do
        get :index

        expect(response.body).to include('SOCIALWISE_RICH_DASHBOARD')
        expect(response.body).to include('"SOCIALWISE_RICH_DASHBOARD":"true"')
      end
    end

    context 'when feature flag is disabled globally' do
      before do
        allow(GlobalConfig).to receive(:get).and_call_original
        allow(GlobalConfig).to receive(:get).with(
          'LOGO', 'LOGO_DARK', 'LOGO_THUMBNAIL',
          'INSTALLATION_NAME',
          'WIDGET_BRAND_URL', 'TERMS_URL',
          'BRAND_URL', 'BRAND_NAME',
          'PRIVACY_URL',
          'DISPLAY_MANIFEST',
          'CREATE_NEW_ACCOUNT_FROM_DASHBOARD',
          'CHATWOOT_INBOX_TOKEN',
          'API_CHANNEL_NAME',
          'API_CHANNEL_THUMBNAIL',
          'ANALYTICS_TOKEN',
          'DIRECT_UPLOADS_ENABLED',
          'HCAPTCHA_SITE_KEY',
          'LOGOUT_REDIRECT_LINK',
          'DISABLE_USER_PROFILE_UPDATE',
          'DEPLOYMENT_ENV',
          'INSTALLATION_PRICING_PLAN',
          'SOCIALWISE_RICH_DASHBOARD'
        ).and_return({
          'SOCIALWISE_RICH_DASHBOARD' => nil
        }.with_indifferent_access)
      end

      it 'includes SOCIALWISE_RICH_DASHBOARD as nil in global config' do
        get :index

        expect(response).to have_http_status(:success)
        expect(assigns(:global_config)).to include('SOCIALWISE_RICH_DASHBOARD' => nil)
      end

      it 'exposes disabled flag to frontend JavaScript' do
        get :index

        expect(response.body).to include('SOCIALWISE_RICH_DASHBOARD')
        expect(response.body).to include('"SOCIALWISE_RICH_DASHBOARD":null')
      end
    end

    context 'when feature flag is not configured' do
      before do
        allow(GlobalConfig).to receive(:get).and_call_original
        allow(GlobalConfig).to receive(:get).with(
          'LOGO', 'LOGO_DARK', 'LOGO_THUMBNAIL',
          'INSTALLATION_NAME',
          'WIDGET_BRAND_URL', 'TERMS_URL',
          'BRAND_URL', 'BRAND_NAME',
          'PRIVACY_URL',
          'DISPLAY_MANIFEST',
          'CREATE_NEW_ACCOUNT_FROM_DASHBOARD',
          'CHATWOOT_INBOX_TOKEN',
          'API_CHANNEL_NAME',
          'API_CHANNEL_THUMBNAIL',
          'ANALYTICS_TOKEN',
          'DIRECT_UPLOADS_ENABLED',
          'HCAPTCHA_SITE_KEY',
          'LOGOUT_REDIRECT_LINK',
          'DISABLE_USER_PROFILE_UPDATE',
          'DEPLOYMENT_ENV',
          'INSTALLATION_PRICING_PLAN',
          'SOCIALWISE_RICH_DASHBOARD'
        ).and_return({}.with_indifferent_access)
      end

      it 'includes SOCIALWISE_RICH_DASHBOARD as nil when not configured' do
        get :index

        expect(response).to have_http_status(:success)
        expect(assigns(:global_config)).to include('SOCIALWISE_RICH_DASHBOARD' => nil)
      end
    end
  end

  describe 'frontend accessibility' do
    before do
      allow(GlobalConfig).to receive(:get).and_call_original
      allow(GlobalConfig).to receive(:get).with(
        'LOGO', 'LOGO_DARK', 'LOGO_THUMBNAIL',
        'INSTALLATION_NAME',
        'WIDGET_BRAND_URL', 'TERMS_URL',
        'BRAND_URL', 'BRAND_NAME',
        'PRIVACY_URL',
        'DISPLAY_MANIFEST',
        'CREATE_NEW_ACCOUNT_FROM_DASHBOARD',
        'CHATWOOT_INBOX_TOKEN',
        'API_CHANNEL_NAME',
        'API_CHANNEL_THUMBNAIL',
        'ANALYTICS_TOKEN',
        'DIRECT_UPLOADS_ENABLED',
        'HCAPTCHA_SITE_KEY',
        'LOGOUT_REDIRECT_LINK',
        'DISABLE_USER_PROFILE_UPDATE',
        'DEPLOYMENT_ENV',
        'INSTALLATION_PRICING_PLAN',
        'SOCIALWISE_RICH_DASHBOARD'
      ).and_return({
        'SOCIALWISE_RICH_DASHBOARD' => 'true',
        'BRAND_NAME' => 'Test Brand'
      }.with_indifferent_access)
    end

    it 'exposes feature flag alongside other global config values' do
      get :index

      global_config = assigns(:global_config)
      expect(global_config).to include('SOCIALWISE_RICH_DASHBOARD' => 'true')
      expect(global_config).to include('BRAND_NAME' => 'Test Brand')
    end

    it 'maintains existing global config structure' do
      get :index

      global_config = assigns(:global_config)
      
      # Verify existing config keys are still present
      expect(global_config).to have_key('APP_VERSION')
      expect(global_config).to have_key('VAPID_PUBLIC_KEY')
      expect(global_config).to have_key('ENABLE_ACCOUNT_SIGNUP')
      expect(global_config).to have_key('IS_ENTERPRISE')
      
      # Verify new feature flag is added
      expect(global_config).to have_key('SOCIALWISE_RICH_DASHBOARD')
    end

    it 'does not break existing functionality' do
      get :index

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:index)
      expect(response.content_type).to include('text/html')
    end
  end

  describe 'rollback capability' do
    it 'allows instant rollback by changing global config' do
      # Initially enabled
      allow(GlobalConfig).to receive(:get).and_call_original
      allow(GlobalConfig).to receive(:get).with(
        'LOGO', 'LOGO_DARK', 'LOGO_THUMBNAIL',
        'INSTALLATION_NAME',
        'WIDGET_BRAND_URL', 'TERMS_URL',
        'BRAND_URL', 'BRAND_NAME',
        'PRIVACY_URL',
        'DISPLAY_MANIFEST',
        'CREATE_NEW_ACCOUNT_FROM_DASHBOARD',
        'CHATWOOT_INBOX_TOKEN',
        'API_CHANNEL_NAME',
        'API_CHANNEL_THUMBNAIL',
        'ANALYTICS_TOKEN',
        'DIRECT_UPLOADS_ENABLED',
        'HCAPTCHA_SITE_KEY',
        'LOGOUT_REDIRECT_LINK',
        'DISABLE_USER_PROFILE_UPDATE',
        'DEPLOYMENT_ENV',
        'INSTALLATION_PRICING_PLAN',
        'SOCIALWISE_RICH_DASHBOARD'
      ).and_return({
        'SOCIALWISE_RICH_DASHBOARD' => 'true'
      }.with_indifferent_access)

      get :index
      expect(assigns(:global_config)['SOCIALWISE_RICH_DASHBOARD']).to eq('true')

      # Simulate rollback by changing config
      allow(GlobalConfig).to receive(:get).with(
        'LOGO', 'LOGO_DARK', 'LOGO_THUMBNAIL',
        'INSTALLATION_NAME',
        'WIDGET_BRAND_URL', 'TERMS_URL',
        'BRAND_URL', 'BRAND_NAME',
        'PRIVACY_URL',
        'DISPLAY_MANIFEST',
        'CREATE_NEW_ACCOUNT_FROM_DASHBOARD',
        'CHATWOOT_INBOX_TOKEN',
        'API_CHANNEL_NAME',
        'API_CHANNEL_THUMBNAIL',
        'ANALYTICS_TOKEN',
        'DIRECT_UPLOADS_ENABLED',
        'HCAPTCHA_SITE_KEY',
        'LOGOUT_REDIRECT_LINK',
        'DISABLE_USER_PROFILE_UPDATE',
        'DEPLOYMENT_ENV',
        'INSTALLATION_PRICING_PLAN',
        'SOCIALWISE_RICH_DASHBOARD'
      ).and_return({
        'SOCIALWISE_RICH_DASHBOARD' => nil
      }.with_indifferent_access)

      get :index
      expect(assigns(:global_config)['SOCIALWISE_RICH_DASHBOARD']).to be_nil
    end
  end
end