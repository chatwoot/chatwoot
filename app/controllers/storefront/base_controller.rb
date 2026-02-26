# rubocop:disable Rails/ApplicationController
class Storefront::BaseController < ActionController::Base
  include StorefrontAuth

  layout 'storefront'

  skip_before_action :verify_authenticity_token
  before_action :set_storefront_locale

  helper_method :storefront_locale, :storefront_rtl?, :storefront_link_params, :product_title, :product_description

  private

  def set_storefront_locale
    locale = params[:locale]&.to_sym
    I18n.locale = %i[en ar].include?(locale) ? locale : :en
  end

  def storefront_locale
    I18n.locale
  end

  def storefront_rtl?
    I18n.locale == :ar
  end

  def storefront_link_params
    { token: storefront_token_param, locale: storefront_locale }
  end

  def product_title(product)
    storefront_rtl? && product.title_ar.present? ? product.title_ar : product.title_en
  end

  def product_description(product)
    storefront_rtl? && product.description_ar.present? ? product.description_ar : product.description_en
  end

  def catalog_settings
    @catalog_settings ||= @account.catalog_settings
  end

  def ensure_catalog_enabled!
    return if catalog_settings&.enabled?

    render 'storefront/catalog_disabled', layout: 'storefront', status: :not_found
  end
end
# rubocop:enable Rails/ApplicationController
