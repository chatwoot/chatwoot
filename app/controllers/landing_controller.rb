class LandingController < ActionController::Base
  def index
    @installation_name = GlobalConfig.get_value('INSTALLATION_NAME') || 'HelpBase'
    @logo = GlobalConfig.get_value('LOGO') || '/brand-assets/logo.svg'
    @logo_dark = GlobalConfig.get_value('LOGO_DARK') || '/brand-assets/logo_dark.svg'
    render layout: 'landing'
  end
end
