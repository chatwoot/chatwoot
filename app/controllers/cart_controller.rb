class CartController < ApplicationController
  layout 'payment'

  def show
    @cart = Cart.includes(:account, cart_items: :product).find_by!(external_payment_id: params[:id])
  rescue ActiveRecord::RecordNotFound
    render :not_found, status: :not_found
  end
end
