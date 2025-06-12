class Public::Api::V1::Portals::BaseController < PublicController
  include SwitchLocale

  before_action :show_plain_layout
  before_action :set_color_scheme
  before_action :set_global_config
  around_action :set_locale
  after_action :allow_iframe_requests

  private

  def show_plain_layout
    @is_plain_layout_enabled = params[:show_plain_layout] == 'true'
  end

  def set_color_scheme
    @theme_from_params = params[:theme] if %w[dark light].include?(params[:theme])
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
    @locale = validate_and_get_locale(params[:locale])

    I18n.with_locale(@locale, &)
  end

  def switch_locale_with_article(&)
    article = Article.find_by(slug: params[:article_slug])
    Rails.logger.info "Article: not found for slug: #{params[:article_slug]}"
    render_404 && return if article.blank?

    article_locale = if article.category.present?
                       article.category.locale
                     else
                       article.portal.default_locale
                     end
    @locale = validate_and_get_locale(article_locale)
    I18n.with_locale(@locale, &)
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options') if @is_plain_layout_enabled
  end

  def render_404
    portal
    render 'public/api/v1/portals/error/404', status: :not_found
  end

  def set_global_config
    @global_config = GlobalConfig.get('LOGO_THUMBNAIL', 'BRAND_NAME', 'BRAND_URL')
  end
end
