# lib/integrations/socialwise_flow/debounce_processor_service.rb
#
# Processor service for debounced SocialWise Flow messages.
# This service is similar to ProcessorService but accepts pre-concatenated content
# instead of extracting content from a single message.

class Integrations::SocialwiseFlow::DebounceProcessorService < Integrations::SocialwiseFlow::ProcessorService
  pattr_initialize [:event_name!, :hook!, :event_data!, :concatenated_content!]

  def perform
    Rails.logger.info '[SOCIALWISE-DEBOUNCE-PROCESSOR] === perform called ==='
    message = event_data[:message]
    Rails.logger.info "[SOCIALWISE-DEBOUNCE-PROCESSOR] Message ID: #{message&.id}"
    Rails.logger.info "[SOCIALWISE-DEBOUNCE-PROCESSOR] Conversation ID: #{message&.conversation&.id}"
    Rails.logger.info "[SOCIALWISE-DEBOUNCE-PROCESSOR] Conversation status: #{message&.conversation&.status}"

    unless should_run_debounce_processor?(message)
      Rails.logger.info '[SOCIALWISE-DEBOUNCE-PROCESSOR] should_run_debounce_processor? returned false, aborting'
      return
    end

    Rails.logger.info "[SOCIALWISE-DEBOUNCE-PROCESSOR] Processing concatenated content for message #{message.id}"
    Rails.logger.info "[SOCIALWISE-DEBOUNCE-PROCESSOR] Content: #{concatenated_content.truncate(200)}"

    process_concatenated_content(message)
    Rails.logger.info '[SOCIALWISE-DEBOUNCE-PROCESSOR] === perform completed ==='
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-DEBOUNCE-PROCESSOR] Error: #{e.class}: #{e.message}"
    Rails.logger.error "[SOCIALWISE-DEBOUNCE-PROCESSOR] Backtrace: #{e.backtrace.first(5).join('\n')}"
    ChatwootExceptionTracker.new(e, account: hook&.account).capture_exception
  end

  private

  def should_run_debounce_processor?(message)
    Rails.logger.info '[SOCIALWISE-DEBOUNCE-PROCESSOR] === CHECKING should_run_debounce_processor ==='
    Rails.logger.info "[SOCIALWISE-DEBOUNCE-PROCESSOR] Message private?: #{message.private?}"

    if message.private?
      Rails.logger.info '[SOCIALWISE-DEBOUNCE-PROCESSOR] BLOCKED: Message is private'
      return false
    end

    # Use the same logic as ProcessorService - accept pending OR open without agent replies and no handoff
    # This reuses the bot_should_respond? method from the parent class
    unless bot_should_respond?
      Rails.logger.info "[SOCIALWISE-DEBOUNCE-PROCESSOR] BLOCKED: Bot should not respond (status: #{conversation.status}, has_agent_reply: #{has_agent_reply?}, handoff_completed: #{handoff_completed?})"
      return false
    end

    Rails.logger.info '[SOCIALWISE-DEBOUNCE-PROCESSOR] PASSED: All checks passed'
    true
  end

  def process_concatenated_content(message)
    Rails.logger.info '[SOCIALWISE-DEBOUNCE-PROCESSOR] === process_concatenated_content called ==='
    response = get_response(message.conversation.contact_inbox.source_id, concatenated_content)

    if response.present?
      Rails.logger.info "[SOCIALWISE-DEBOUNCE-PROCESSOR] Response received, processing..."
      process_response(message, response)
    else
      Rails.logger.info '[SOCIALWISE-DEBOUNCE-PROCESSOR] No response from webhook'
    end
  end
end
