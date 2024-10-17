class Webhooks::Integrations::CustomApiController < ActionController::API
  def process_order_created
    process_event('order_created')
  end

  def process_order_status
    process_event('order_status_update')
  end

  def process_order_update
    process_event('order_update')
  end

  def process_order_deleted
    process_event('order_deleted')
  end

  def process_order_item_update
    process_event('order_item_update')
  end

  def process_contact_updated
    process_event('contact_updated')
  end

  def process_cart_recovery
    process_event('cart_recovery')
  end

  private

  def process_event(event_type)
    return if custom_api.nil?

    custom_params = params.to_unsafe_hash.merge('event_type' => event_type, 'custom_api' => custom_api)
    Webhooks::CustomApiEventsJob.perform_later(custom_params)
    head :ok
  end

  def custom_api
    CustomApi.find_by(id: params[:api_id])
  end
end
