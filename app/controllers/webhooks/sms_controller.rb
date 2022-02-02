class Webhooks::SmsController < ActionController::API
  def process_payload
    Webhooks::SmsEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end
end
