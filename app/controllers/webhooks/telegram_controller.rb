class Webhooks::TelegramController < ActionController::API
  def process_payload
    Rails.logger.info "[TELEGRAM WEBHOOK] Params: #{params.to_unsafe_hash.inspect}"
    Webhooks::TelegramEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end
end
