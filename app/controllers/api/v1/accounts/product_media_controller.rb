class Api::V1::Accounts::ProductMediaController < Api::V1::Accounts::BaseController
  before_action :product_catalog
  before_action :product_medium, only: [:set_primary]
  before_action :check_authorization

  def set_primary
    @product_medium.update!(is_primary: true)
    head :ok
  end

  private

  def product_catalog
    @product_catalog ||= Current.account.product_catalogs.find(params[:product_catalog_id])
  end

  def product_medium
    @product_medium ||= @product_catalog.product_media.find(params[:id])
  end
end
