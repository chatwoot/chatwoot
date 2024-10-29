class Webhooks::LineController < ActionController::API
  def process_payload
    Webhooks::LineEventsJob.perform_later(params: params.to_unsafe_hash, signature: request.headers['x-line-signature'], post_body: request.raw_post)
    head :ok
  end
end
