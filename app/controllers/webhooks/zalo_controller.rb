class Webhooks::ZaloController < ActionController::API
  def process_payload
    Rails.logger.info('Zalo webhook received events')
    Webhooks::ZaloEventsJob.perform_later(params.to_unsafe_hash, signature: request.headers['X-ZEvent-Signature'], post_body: request.body.read)
    head :ok
  end
end
