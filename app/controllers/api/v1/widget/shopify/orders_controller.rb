class Api::V1::Widget::Shopify::OrdersController < Api::V1::Widget::BaseController
  def index
    orders_populated = inbox.account.orders.where(customer_id: @contact.custom_attributes['shopify_orders_populated']);

    return render json: {orders: [], populated: false}, head: :ok unless orders_populated

    orders = inbox.account.orders.where(customer_id: @contact.custom_attributes['shopify_customer_id']);

    render json: {orders: orders, populated: true}, head: :ok
  end
end
