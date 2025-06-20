class Api::V1::Widget::Shopify::OrdersController < Api::V1::Widget::BaseController
  def index
    render json: {orders: inbox.account.orders.where(customer_id: @contact.custom_attributes['shopify_customer_id'])}
  end
end
