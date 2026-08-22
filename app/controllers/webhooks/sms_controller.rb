class Webhooks::SmsController < ActionController::API
  def process_payload
    Webhooks::SmsEventsJob.perform_later(params['_json']&.first&.to_unsafe_hash&.with_indifferent_access)
    head :ok
  end
end
