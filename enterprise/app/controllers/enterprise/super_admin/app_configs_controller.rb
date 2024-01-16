module Enterprise::SuperAdmin::AppConfigsController
  private

  def allowed_configs
    return super if ChatwootHub.pricing_plan == 'community'

    case @config
    when 'custom_branding'
      @allowed_configs = %w[
        LOGO_THUMBNAIL
        LOGO
        BRAND_NAME
        INSTALLATION_NAME
        BRAND_URL
        WIDGET_BRAND_URL
        TERMS_URL
        PRIVACY_URL
      ]
    else
      super
    end
  end
end
