module Enterprise::SuperAdmin::AppConfigsController
  private

  def allowed_configs
    @allowed_configs = custom_branding_options + internal_config_options + %w[CAPTAIN_API_URL CAPTAIN_APP_URL]
  end
  

  def custom_branding_options
    %w[
      LOGO_THUMBNAIL
      LOGO
      LOGO_DARK
      BRAND_NAME
      INSTALLATION_NAME
      BRAND_URL
      WIDGET_BRAND_URL
      TERMS_URL
      PRIVACY_URL
      DISPLAY_MANIFEST
    ]
  end

  def internal_config_options
    %w[CHATWOOT_INBOX_TOKEN CHATWOOT_INBOX_HMAC_KEY ANALYTICS_TOKEN CLEARBIT_API_KEY DASHBOARD_SCRIPTS BLOCKED_EMAIL_DOMAINS]
  end
end
