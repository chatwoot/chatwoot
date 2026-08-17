class Captain::Copilot::ReplySuggestionJob < ApplicationJob
  queue_as :default

  def perform(assistant:, conversation_id:, user_id:, copilot_thread_id:)
    Rails.logger.info("#{self.class.name} Copilot reply suggestion job for assistant_id=#{assistant.id} user_id=#{user_id}")

    Captain::Copilot::ReplySuggestionService.new(
      assistant: assistant,
      conversation_id: conversation_id,
      user_id: user_id,
      copilot_thread_id: copilot_thread_id
    ).generate_response
  end
end
