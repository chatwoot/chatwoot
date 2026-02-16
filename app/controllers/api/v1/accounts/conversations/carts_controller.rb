class Api::V1::Accounts::Conversations::CartsController < Api::V1::Accounts::Conversations::BaseController
  skip_before_action :conversation
  before_action :set_conversation

  def create
    cart = Carts::CreateService.new(
      conversation: @conversation,
      creator: Current.user,
      items: permitted_params[:items]
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
    params.permit(items: [:product_id, :quantity])
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

  def set_conversation
    @conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize Cart, :create?
  end
end
