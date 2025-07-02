# frozen_string_literal: true

class Captain::Copilot::AgentsResponseJob < ApplicationJob
  queue_as :default

  def perform(copilot_thread_id:, message_content:, conversation_id: nil, user_id: nil)
    Rails.logger.debug do
      "[DEBUG] AgentsResponseJob: Starting with thread_id: #{copilot_thread_id}, message: #{message_content}, conversation_id: #{conversation_id}, user_id: #{user_id}"
    end

    copilot_thread = CopilotThread.find(copilot_thread_id)
    Rails.logger.debug { "[DEBUG] AgentsResponseJob: Found copilot_thread: #{copilot_thread.inspect}" }

    # Use the new AgentsChatService with direct parameters
    Rails.logger.debug '[DEBUG] AgentsResponseJob: Creating AgentsChatService'
    service = AgentsChatService.new(
      copilot_thread: copilot_thread,
      message_content: message_content,
      conversation_id: conversation_id,
      user_id: user_id
    )

    Rails.logger.debug '[DEBUG] AgentsResponseJob: Calling service.perform'
    service.perform
    Rails.logger.debug '[DEBUG] AgentsResponseJob: Service completed successfully'
  rescue StandardError => e
    Rails.logger.debug { "[DEBUG] AgentsResponseJob: ERROR - #{e.class}: #{e.message}" }
    Rails.logger.debug '[DEBUG] AgentsResponseJob: FULL BACKTRACE:'
    e.backtrace.each { |line| Rails.logger.debug "[DEBUG] #{line}" }
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
    Rails.logger.debug '[DEBUG] AgentsResponseJob: Created error response message'
  end
end