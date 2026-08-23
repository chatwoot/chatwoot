class CaptainListener < BaseListener
  include ::Events::Types

  def message_updated(event)
    message = event.data[:message]
    return unless message.input_csat?

    response = CsatSurveyResponse.find_by(message: message)
    return unless response

    tracker(message.conversation).record_csat(response: response)
  end

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    tracker(conversation).record_resolution(at: event.timestamp)

    assistant = conversation.inbox.captain_assistant

    return unless conversation.inbox.captain_active?

    # Memory/FAQ generation is an LLM-backed secondary effect: a failure here must
    # never break the shared event pipeline (notifications, webhooks, automation
    # rules) that listens on the same resolution event.
    generate_post_resolution_memory(assistant, conversation)
  end

  def generate_post_resolution_memory(assistant, conversation)
    Captain::Llm::ContactNotesService.new(assistant, conversation).generate_and_update_notes if assistant.config['feature_memory'].present?
    Captain::Llm::ConversationFaqJob.perform_later(conversation, assistant) if assistant.config['feature_faq'].present?
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    Rails.logger.error(
      "[CAPTAIN][CaptainListener] Post-resolution memory/FAQ generation failed for conversation=#{conversation.display_id}: #{e.message}"
    )
  end

  private

  def tracker(conversation)
    Captain::ConversationOutcomeTracker.new(conversation: conversation)
  end
end
