class Webhooks::WahaController < ActionController::API
  def process_payload
    Webhooks::WahaEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end
end
