# lib/integrations/socialwise_flow/debounce_processor_service.rb
#
# Processor service for debounced SocialWise Flow messages.
# This service is similar to ProcessorService but accepts pre-concatenated content
# instead of extracting content from a single message.

class Integrations::SocialwiseFlow::DebounceProcessorService < Integrations::SocialwiseFlow::ProcessorService
  pattr_initialize [:event_name!, :hook!, :event_data!, :concatenated_content!]

  def perform
    message = event_data[:message]
    return unless should_run_debounce_processor?(message)

    Rails.logger.info "[SOCIALWISE-DEBOUNCE-PROCESSOR] Processing concatenated content for message #{message.id}"
    Rails.logger.info "[SOCIALWISE-DEBOUNCE-PROCESSOR] Content: #{concatenated_content.truncate(200)}"

    process_concatenated_content(message)
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-DEBOUNCE-PROCESSOR] Error: #{e.class}: #{e.message}"
    Rails.logger.error "[SOCIALWISE-DEBOUNCE-PROCESSOR] Backtrace: #{e.backtrace.first(5).join('\n')}"
    ChatwootExceptionTracker.new(e, account: hook&.account).capture_exception
  end

  private

  def should_run_debounce_processor?(message)
    return false if message.private?
    return false unless message.conversation.pending?

    true
  end

  def process_concatenated_content(message)
    response = get_response(message.conversation.contact_inbox.source_id, concatenated_content)
    process_response(message, response) if response.present?
  end
end
