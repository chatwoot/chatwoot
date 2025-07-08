class ChatServiceJob
  include Sidekiq::Job

  LOADING_DELAY_SECONDS = 10

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message

    # flag_key = "chat_service_running_#{message_id}"
    # ::Redis::Alfred.set(flag_key, 'running', ex: 3600)

    # ChatServiceWatchdogJob.perform_in(LOADING_DELAY_SECONDS, message_id)

    chat_service = Captain::Copilot::ChatService.new(message)
    chat_service.perform

    # ::Redis::Alfred.del(flag_key)
  end
end
