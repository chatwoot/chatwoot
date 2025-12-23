class Survey::ResponsesController < ActionController::Base
  before_action :set_global_config
  def show; end

  private

  def set_global_config
    config = GlobalConfig.get('LOGO_THUMBNAIL', 'BRAND_NAME', 'WIDGET_BRAND_URL', 'INSTALLATION_NAME')
    
    # Load branding from BrandingConfig if available
    branding = BrandingConfig.instance rescue nil
    if branding
      config['BRAND_NAME'] = branding.brand_name
      config['BRAND_WEBSITE'] = branding.brand_website
      config['LOGO_THUMBNAIL'] = branding.logo_compact_url || branding.logo_main_url || config['LOGO_THUMBNAIL']
    end
    
    @global_config = config
  end
end
