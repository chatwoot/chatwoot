class Captain::Copilot::ReplySuggestionJob < ApplicationJob
  queue_as :default

  retry_on Captain::Copilot::ReplySuggestionService::GenerationError, wait: 3.seconds, attempts: 3 do |job, _error|
    job.send(:persist_failure_response)
  end

  def perform(assistant:, conversation_id:, user_id:, copilot_thread_id:)
    Rails.logger.info("#{self.class.name} Copilot reply suggestion job for assistant_id=#{assistant.id} user_id=#{user_id}")

    @reply_suggestion_service = Captain::Copilot::ReplySuggestionService.new(
      assistant: assistant,
      conversation_id: conversation_id,
      user_id: user_id,
      copilot_thread_id: copilot_thread_id
    )
    @reply_suggestion_service.generate_response
  end

  private

  def persist_failure_response
    @reply_suggestion_service.persist_failure_response
  end
end
