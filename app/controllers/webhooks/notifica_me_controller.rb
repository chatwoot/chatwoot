class Webhooks::NotificaMeController < ActionController::API
  def process_payload
    Webhooks::NotificaMeEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end
end
