class Api::V1::Accounts::Conversations::OrdersController < Api::V1::Accounts::Conversations::BaseController
  skip_before_action :conversation
  before_action :set_conversation

  def create
    order = Orders::CreateService.new(
      conversation: @conversation,
      creator: Current.user,
      items: permitted_params[:items]
    ).perform

    render json: {
      success: true,
      data: order_response(order)
    }, status: :created
  rescue StandardError => e
    Rails.logger.error "Order creation failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def permitted_params
    params.permit(items: [:product_id, :quantity])
  end

  def order_response(order)
    {
      order_id: order.id,
      external_payment_id: order.external_payment_id,
      payment_url: order.payment_url,
      subtotal: order.subtotal,
      total: order.total,
      currency: order.currency,
      status: order.status,
      items: order.order_items.includes(:product).map do |item|
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
    authorize Order, :create?
  end
end
