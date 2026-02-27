class OrderController < ApplicationController
  layout 'payment'

  def show
    @order = Order.includes(:account, order_items: :product).find_by!(external_payment_id: params[:id])
  rescue ActiveRecord::RecordNotFound
    render :not_found, status: :not_found
  end
end
