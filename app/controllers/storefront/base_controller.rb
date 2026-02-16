# rubocop:disable Rails/ApplicationController
class Storefront::BaseController < ActionController::Base
  include StorefrontAuth

  layout 'storefront'

  skip_before_action :verify_authenticity_token

  private

  def catalog_settings
    @catalog_settings ||= @account.catalog_settings
  end

  def ensure_catalog_enabled!
    return if catalog_settings&.enabled?

    render 'storefront/catalog_disabled', layout: 'storefront', status: :not_found
  end
end
# rubocop:enable Rails/ApplicationController
