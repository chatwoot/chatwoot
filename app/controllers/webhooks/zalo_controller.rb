class Webhooks::ZaloController < ActionController::API
  def process_payload
    Rails.logger.info("Processing Zalo webhook payload: #{params.to_unsafe_hash.inspect}")
    Webhooks::ZaloEventsJob.perform_later(params: params.to_unsafe_hash)
    head :ok
  end
end
