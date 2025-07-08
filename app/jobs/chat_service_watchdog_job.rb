class ChatServiceWatchdogJob
  include Sidekiq::Job

  def perform(message_id)
    flag_key = "chat_service_running_#{message_id}"
    return unless ::Redis::Alfred.get(flag_key) == 'running'

    message = Message.find_by(id: message_id)
    return unless message

    chat_service = Captain::Copilot::ChatService.new(message)
    chat_service.notify_if_long_running
  end
end
