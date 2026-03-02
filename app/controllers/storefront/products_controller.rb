class Storefront::ProductsController < Storefront::BaseController
  before_action :ensure_catalog_enabled!

  def index
    @products = @account.products.where('stock IS NULL OR stock != 0').order(created_at: :desc)
    @currency = catalog_settings.currency
  end

  def show
    @product = @account.products.find(params[:id])
    @currency = catalog_settings.currency
    cart = session["storefront_cart_#{@account.id}_#{current_contact.id}"] || {}
    @cart_qty = cart[@product.id.to_s].to_i
  end
end
