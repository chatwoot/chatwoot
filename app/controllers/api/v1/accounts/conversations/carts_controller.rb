class Api::V1::Accounts::Conversations::CartsController < Api::V1::Accounts::Conversations::BaseController
  def create
    cart = Carts::CreateService.new(
      conversation: @conversation,
      user: Current.user,
      items: permitted_params[:items],
      currency: permitted_params[:currency]
    ).perform

    render json: {
      success: true,
      data: cart_response(cart)
    }, status: :created
  rescue StandardError => e
    Rails.logger.error "Cart creation failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def permitted_params
    params.permit(:currency, items: [:product_id, :quantity])
  end

  def cart_response(cart)
    {
      cart_id: cart.id,
      external_payment_id: cart.external_payment_id,
      payment_url: cart.payment_url,
      subtotal: cart.subtotal,
      total: cart.total,
      currency: cart.currency,
      status: cart.status,
      items: cart.cart_items.includes(:product).map do |item|
        {
          product_id: item.product_id,
          title: item.product.title_en,
          quantity: item.quantity,
          unit_price: item.unit_price,
          total_price: item.total_price
        }
      end
    }
  end
end
