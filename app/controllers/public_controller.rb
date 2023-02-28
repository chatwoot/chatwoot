# TODO: we should switch to ActionController::API for the base classes
# One of the specs is failing when I tried doing that, lets revisit in future
class PublicController < ActionController::Base
  include RequestExceptionHandler
  skip_before_action :verify_authenticity_token
  around_action :set_locale

  private

  def ensure_custom_domain_request
    domain = request.host

    return if [URI.parse(ENV.fetch('FRONTEND_URL', '')).host, URI.parse(ENV.fetch('HELPCENTER_URL', '')).host].include?(domain)

    @portal = ::Portal.find_by(custom_domain: domain)
    return if @portal.present?

    render json: {
      error: "Domain: #{domain} is not registered with us. \
      Please send us an email at support@chatwoot.com with the custom domain name and account API key"
    }, status: :unauthorized and return
  end

  def set_locale(&)
    switch_locale(&) if params[:locale].present?
  end

  def switch_locale(&)
    locale_without_variant = params[:locale].split('_')[0]
    is_locale_available = I18n.available_locales.map(&:to_s).include?(params[:locale])
    is_locale_variant_available = I18n.available_locales.map(&:to_s).include?(locale_without_variant)
    if is_locale_available
      @locale = params[:locale]
    elsif is_locale_variant_available
      @locale = locale_without_variant
    end

    I18n.with_locale(@locale, &)
  end
end
