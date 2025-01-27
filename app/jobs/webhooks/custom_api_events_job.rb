class Webhooks::CustomApiEventsJob < ApplicationJob
  include Events::Types

  queue_as :low

  def perform(params = {})
    event_type = params['event_type']
    case event_type
    when 'order_created'
      order_created_handler(params)
    when 'order_status_update'
      order_status_handler(params)
    when 'order_update'
      Integrations::CustomApi::CreateOrUpdateOrderService.new(nil, params, params['custom_api']).perform
    when 'order_deleted'
      Integrations::CustomApi::DeleteOrderService.new(params, params['custom_api']).perform
    when 'order_item_update'
      Integrations::CustomApi::CreateOrUpdateOrderItemService.new(params, params['lineItems']).perform
    when 'contact_updated'
      Integrations::CustomApi::CreateOrUpdateContactService.new(nil, params['custom_api'], params).perform
    when 'cart_recovery'
      dispatcher_dispatch('cart_recovery', params)
    end
  end
end

private

def order_status_handler(params)
  order = Integrations::CustomApi::UpdateOrderStatusService.new(params['id'], params['fulfillmentStatus'], params['trackingCode'],
                                                                params['paymentStatus']).perform
  dispatcher_dispatch('order.status_updated', order)
end

def order_created_handler(params)
  order = Integrations::CustomApi::ImportOrderService.new(custom_api: params['custom_api']).process_order(params)
  dispatcher_dispatch('order.created', order)
end

def dispatcher_dispatch(event_name, changed_attributes = nil)
  Rails.configuration.dispatcher.dispatch(event_name, Time.zone.now,
                                          changed_attributes)
end
