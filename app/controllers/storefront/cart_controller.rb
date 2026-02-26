class Storefront::CartController < Storefront::BaseController
  before_action :ensure_catalog_enabled!

  # GET /store/:account_id/cart
  def show
    @cart_items = load_cart_items
    @currency = catalog_settings.currency
    @cart_subtotal = @cart_items.sum(&:total_price)
  end

  # POST /store/:account_id/cart/items
  def add_item
    add_product_to_session_cart
    respond_with_cart('Added')
  end

  # PATCH /store/:account_id/cart/items/:id
  def update_item
    update_session_cart_item
    respond_with_cart('Updated')
  end

  # DELETE /store/:account_id/cart/items/:id
  def remove_item
    remove_session_cart_item
    respond_with_cart('Removed')
  end

  private

  def session_key
    "storefront_cart_#{@account.id}_#{current_contact.id}"
  end

  def session_cart
    session[session_key] || {}
  end

  def save_session_cart(data)
    session[session_key] = data
  end

  def cart_count
    session_cart.values.sum(&:to_i)
  end

  def respond_with_cart(message)
    respond_to do |format|
      format.json { render json: { cart_count: cart_count, message: message } }
      format.html { redirect_to storefront_cart_path(@account, **storefront_link_params) }
    end
  end

  def add_product_to_session_cart
    product = @account.products.find(params[:product_id])
    qty = params[:quantity].to_i.clamp(1, 99)
    cart_data = session_cart
    cart_data[product.id.to_s] = (cart_data[product.id.to_s].to_i + qty).clamp(1, 99)
    save_session_cart(cart_data)
  end

  def update_session_cart_item
    cart_data = session_cart
    qty = params[:quantity].to_i
    qty <= 0 ? cart_data.delete(params[:id].to_s) : cart_data[params[:id].to_s] = qty.clamp(1, 99)
    save_session_cart(cart_data)
  end

  def remove_session_cart_item
    cart_data = session_cart
    cart_data.delete(params[:id].to_s)
    save_session_cart(cart_data)
  end

  def load_cart_items
    cart_data = session_cart
    return [] if cart_data.blank?

    product_ids = cart_data.keys.map(&:to_i)
    products = @account.products.where(id: product_ids).index_by(&:id)

    cart_data.filter_map do |product_id, quantity|
      product = products[product_id.to_i]
      next unless product

      OpenStruct.new(
        product: product,
        quantity: quantity.to_i,
        total_price: product.price * quantity.to_i
      )
    end
  end
end
