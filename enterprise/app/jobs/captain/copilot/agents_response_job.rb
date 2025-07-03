# frozen_string_literal: true

class Captain::Copilot::AgentsResponseJob < ApplicationJob
  queue_as :default

  def perform(copilot_thread_id:, message_content:, conversation_id: nil, user_id: nil)
    copilot_thread = CopilotThread.find(copilot_thread_id)

    # Use the new AgentsChatService with direct parameters
    service = Captain::Copilot::AgentsChatService.new(
      copilot_thread: copilot_thread,
      message_content: message_content,
      conversation_id: conversation_id,
      user_id: user_id
    )

    service.perform
  rescue StandardError => e
    Rails.logger.error "AgentsResponseJob Error: #{e.class}: #{e.message}"
    Rails.logger.error 'Full backtrace:'
    e.backtrace.each { |line| Rails.logger.error line }

    # Create an error response if the job fails
    copilot_thread&.copilot_messages&.create!(
      message_type: 'assistant',
      message: {
        content: 'I apologize, but I encountered an error while processing your request. Please try again.'
      }
    )
  end
end