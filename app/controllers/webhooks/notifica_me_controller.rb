class Webhooks::NotificaMeController < ActionController::API
  def process_payload
    Rails.logger.error(">>>>>> params.to_unsafe_hash #{params.to_unsafe_hash}")
    Webhooks::NotificaMeEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end
end
