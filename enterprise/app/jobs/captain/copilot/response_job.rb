class Captain::Copilot::ResponseJob < ApplicationJob
  queue_as :default

  # Keep the existing job arguments explicit so queued jobs without request_type can still run.
  def perform(assistant:, conversation_id:, user_id:, copilot_thread_id:, message:, request_type: nil) # rubocop:disable Metrics/ParameterLists
    Rails.logger.info("#{self.class.name} Copilot response job for assistant_id=#{assistant.id} user_id=#{user_id}")

    return generate_reply_suggestion(assistant, conversation_id, user_id, copilot_thread_id) if request_type == 'reply_suggestion'

    generate_chat_response(assistant, conversation_id, user_id, copilot_thread_id, message)
  end

  private

  def generate_reply_suggestion(assistant, conversation_id, user_id, copilot_thread_id)
    Captain::Copilot::ReplySuggestionService.new(
      assistant: assistant,
      conversation_id: conversation_id,
      user_id: user_id,
      copilot_thread_id: copilot_thread_id
    ).generate_response
  end

  def generate_chat_response(assistant, conversation_id, user_id, copilot_thread_id, message)
    service = Captain::Copilot::ChatService.new(
      assistant,
      user_id: user_id,
      copilot_thread_id: copilot_thread_id,
      conversation_id: conversation_id
    )
    # When using copilot_thread, message is already in previous_history
    # Pass nil to avoid duplicate
    service.generate_response(copilot_thread_id.present? ? nil : message)
  end
end
