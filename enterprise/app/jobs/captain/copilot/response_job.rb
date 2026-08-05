class Captain::Copilot::ResponseJob < ApplicationJob
  queue_as :default

  def perform(assistant:, conversation_id:, user_id:, copilot_thread_id:, message:)
    Rails.logger.info("#{self.class.name} Copilot response job for assistant_id=#{assistant.id} user_id=#{user_id}")
    generate_chat_response(
      assistant: assistant,
      conversation_id: conversation_id,
      user_id: user_id,
      copilot_thread_id: copilot_thread_id,
      message: message
    )
  end

  private

  def generate_chat_response(assistant:, conversation_id:, user_id:, copilot_thread_id:, message:)
    config = {
      user_id: user_id,
      copilot_thread_id: copilot_thread_id,
      conversation_id: conversation_id
    }
    if message.is_a?(Hash) && (message.key?(:request_type) || message.key?('request_type'))
      input = message.with_indifferent_access
      config[:request_type] = input[:request_type]
      message = input[:content]
    end

    service = Captain::Copilot::ChatService.new(assistant, **config)
    # When using copilot_thread, message is already in previous_history
    # Pass nil to avoid duplicate
    service.generate_response(copilot_thread_id.present? ? nil : message)
  end
end
