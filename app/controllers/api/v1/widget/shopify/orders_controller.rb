class Api::V1::Widget::Shopify::OrdersController < Api::V1::Widget::BaseController
  def index
    orders = inbox.account.orders.where(customer_id: @contact.custom_attributes['shopify_customer_id']);

    render json: {orders: orders, populated: true}, head: :ok
  end
end
