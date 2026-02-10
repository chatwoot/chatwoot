class Storefront::BaseController < ApplicationController
  include StorefrontAuth

  layout 'storefront'

  # Skip Devise token auth — storefront uses its own token system
  skip_before_action :set_current_user
  skip_before_action :verify_authenticity_token, only: [:add_item, :update_item, :remove_item]

  private

  def catalog_settings
    @catalog_settings ||= @account.catalog_settings
  end

  def ensure_catalog_enabled!
    return if catalog_settings&.enabled?

    render 'storefront/catalog_disabled', layout: 'storefront', status: :not_found
  end
end
