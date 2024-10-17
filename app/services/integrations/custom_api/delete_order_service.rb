class Integrations::CustomApi::DeleteOrderService
  def initialize(order_data, custom_api)
    @order_data = order_data
    @custom_api = custom_api
  end

  def perform
    delete_order
  end

  private

  def delete_order
    order = Order.find_by(order_key: @order_data['id'], platform: @custom_api['name'])
    order.destroy!
  end
end
