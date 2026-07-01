class Webhooks::ZaloOaController < ActionController::API
  def process_payload
    Webhooks::ZaloOaEventsJob.perform_later(params: params.to_unsafe_hash)
    head :ok
  end
end
