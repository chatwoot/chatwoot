class Webhooks::ZaloController < ActionController::API
  def process_payload
    # Webhooks::ZaloEventsJob.perform_later(params: params.to_unsafe_hash)
    head :ok
  end
end
