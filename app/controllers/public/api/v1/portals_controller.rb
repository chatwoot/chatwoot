class Public::Api::V1::PortalsController < Public::Api::V1::Portals::BaseController
  include PortalHomeData

  before_action :ensure_custom_domain_request, only: [:show]
  before_action :redirect_to_portal_with_locale, only: [:show]
  before_action :portal
  before_action :set_portal_layout
  before_action :set_view_variant
  before_action :ensure_portal_feature_enabled
  before_action :load_home_data, only: [:show], if: -> { @portal_layout == 'documentation' }
  layout 'portal'

  def show
    @og_image_url = helpers.set_og_image_url('', @portal.localized_value('header_text', @locale))
  end

  def sitemap
    @help_center_url = @portal.custom_domain || ChatwootApp.help_center_root
    # if help_center_url does not contain a protocol, prepend it with https
    @help_center_url = "https://#{@help_center_url}" unless @help_center_url.include?('://')
  end

  private

  def portal
    @portal ||= Portal.find_by!(slug: params[:slug], archived: false)
    @locale = params[:locale] || @portal.default_locale
  end

  def redirect_to_portal_with_locale
    return if params[:locale].present?

    portal
    redirect_to "/hc/#{@portal.slug}/#{@portal.default_locale}"
  end
end
