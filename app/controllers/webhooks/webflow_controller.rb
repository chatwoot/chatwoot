class Webhooks::WebflowController < ActionController::API
  def process_payload
    Webhooks::WebflowEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end
end
