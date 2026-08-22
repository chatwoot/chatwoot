class Webhooks::LineController < ActionController::API
  def process_payload
    raw = params.to_unsafe_hash
    wrapped = raw.key?('line') || raw.key?(:line) ? raw : raw.merge('line' => raw.except('line_channel_id', 'controller', 'action'))
    Webhooks::LineEventsJob.perform_later(params: wrapped.with_indifferent_access, signature: request.headers['x-line-signature'], post_body: request.raw_post)
    head :ok
  end
end
