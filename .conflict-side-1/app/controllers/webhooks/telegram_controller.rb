class Webhooks::TelegramController < ActionController::API
  def process_payload
    Webhooks::TelegramEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end
end
