class Public::Api::V1::Portals::BaseController < PublicController
  around_action :set_locale

  private

  def set_locale(&)
    switch_locale_with_portal(&) if params[:locale].present?
  end

  def switch_locale_with_portal(&)
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
