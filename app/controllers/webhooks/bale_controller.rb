class Webhooks::BaleController < ActionController::API
  def process_payload
    Webhooks::BaleEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end
end
