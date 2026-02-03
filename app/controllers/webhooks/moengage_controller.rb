class Webhooks::MoengageController < ActionController::API
  def process_payload
    Webhooks::MoengageEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end
end
