class Webhooks::TelnyxSmsController < ActionController::API
  def process_payload
    if Rails.env.development?
      Webhooks::TelnyxSmsEventsJob.perform_now(params.to_unsafe_hash)
    else
      Webhooks::TelnyxSmsEventsJob.perform_later(params.to_unsafe_hash)
    end

    head :ok
  end
end
