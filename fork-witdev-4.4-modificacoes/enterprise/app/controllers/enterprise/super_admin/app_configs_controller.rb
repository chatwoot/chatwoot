module Enterprise::SuperAdmin::AppConfigsController
  private

  def allowed_configs
    return super if ChatwootHub.pricing_plan == 'community'

    case @config
    when 'custom_branding'
      @allowed_configs = custom_branding_options
    when 'internal'
      @allowed_configs = internal_config_options
    when 'captain'
      @allowed_configs = %w[CAPTAIN_OPEN_AI_API_KEY CAPTAIN_OPEN_AI_MODEL CAPTAIN_FIRECRAWL_API_KEY]
    when 'audit_logs'
      @allowed_configs = %w[ENABLE_AUDIT_LOGS AUDIT_LOG_RETENTION_DAYS AUDIT_LOG_EXPORT_FORMAT]
    when 'disable_branding'
      @allowed_configs = %w[HIDE_CHATWOOT_BRANDING CUSTOM_POWERED_BY_TEXT REMOVE_WIDGET_BRANDING REMOVE_EMAIL_BRANDING]
    when 'line'
      @allowed_configs = %w[LINE_CHANNEL_ID LINE_CHANNEL_SECRET LINE_CHANNEL_ACCESS_TOKEN LINE_WEBHOOK_URL]
    when 'help_center'
      @allowed_configs = %w[HELP_CENTER_DOMAIN HELP_CENTER_THEME HELP_CENTER_CUSTOM_CSS HELP_CENTER_ANALYTICS_ID]
    else
      super
    end
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
    %w[CHATWOOT_INBOX_TOKEN CHATWOOT_INBOX_HMAC_KEY ANALYTICS_TOKEN CLEARBIT_API_KEY DASHBOARD_SCRIPTS INACTIVE_WHATSAPP_NUMBERS BLOCKED_EMAIL_DOMAINS
       CAPTAIN_CLOUD_PLAN_LIMITS ACCOUNT_SECURITY_NOTIFICATION_WEBHOOK_URL CHATWOOT_INSTANCE_ADMIN_EMAIL]
  end
end
