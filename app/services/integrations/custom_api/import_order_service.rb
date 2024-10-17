class Integrations::CustomApi::ImportOrderService < Integrations::CustomApi::ImportOrderBaseService
  def import_orders
    response = fetch_orders
    orders = response['orders']

    orders.each do |order_data|
      process_order(order_data)
    rescue StandardError => e

      Rails.logger.error("Failed to process order: #{e.message}")
      next
    end

    update_orders_last_update
  end

  def process_order(order_data)
    ActiveRecord::Base.transaction do
      contact = Integrations::CustomApi::CreateOrUpdateContactService.new(order_data, custom_api, nil).perform
      order = Integrations::CustomApi::CreateOrUpdateOrderService.new(contact, order_data, custom_api).perform
      Integrations::CustomApi::CreateOrUpdateOrderItemService.new(order, order_data['lineItems']).perform

      order
    end
  end

  private

  def fetch_orders
    perform_request(endpoint: 'orders')
  end
end
