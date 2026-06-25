class Public::Api::V1::Portals::BaseController < PublicController
  include SwitchLocale

  before_action :show_plain_layout
  before_action :set_color_scheme
  before_action :set_global_config
  around_action :set_locale
  after_action :allow_iframe_requests

  PORTAL_LAYOUTS = %w[classic documentation].freeze

  private

  def show_plain_layout
    @is_plain_layout_enabled = params[:show_plain_layout] == 'true'
  end

  def set_color_scheme
    @theme_from_params = params[:theme] if %w[dark light].include?(params[:theme])
  end

  def set_portal_layout
    @portal_layout = PORTAL_LAYOUTS.include?(@portal&.layout) ? @portal.layout : 'classic'
  end

  def set_view_variant
    request.variant = :documentation if @portal_layout == 'documentation' && !@is_plain_layout_enabled
  end

  def portal
    @portal ||= Portal.find_by!(slug: params[:slug], archived: false)
  end

  def set_locale(&)
    switch_locale_with_portal(&) if params[:locale].present?
    switch_locale_with_article(&) if params[:article_slug].present?

    yield
  end

  def switch_locale_with_portal(&)
    # Keep @locale as the portal's own locale code (e.g. th_TH) for content queries,
    # while UI translations fall back to an available I18n locale (e.g. th).
    @locale = params[:locale]

    I18n.with_locale(validate_and_get_locale(@locale), &)
  end

  def switch_locale_with_article(&)
    article = Article.find_by(slug: params[:article_slug])
    Rails.logger.info "Article: not found for slug: #{params[:article_slug]}"
    render_404 && return if article.blank?

    @locale = if article.category.present?
                article.category.locale
              else
                article.locale
              end
    I18n.with_locale(validate_and_get_locale(@locale), &)
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options') if @is_plain_layout_enabled
  end

  def render_404
    portal
    render 'public/api/v1/portals/error/404', status: :not_found
  end

  def set_global_config
    @global_config = GlobalConfig.get('LOGO_THUMBNAIL', 'BRAND_NAME', 'BRAND_URL', 'INSTALLATION_NAME')
  end
end
