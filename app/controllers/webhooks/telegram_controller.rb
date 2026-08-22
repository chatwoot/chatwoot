class Webhooks::TelegramController < ActionController::API
  def process_payload
    telegram_payload = params.except(:bot_token, :controller, :action).to_unsafe_hash
    Webhooks::TelegramEventsJob.perform_later(
      { bot_token: params[:bot_token], telegram: telegram_payload }.with_indifferent_access
    )
    head :ok
  end
end
