class CaptainListener < BaseListener
  include ::Events::Types

  def conversation_language_detected(event)
    conversation = event.data[:conversation]
    message = event.data[:message]
    assistant = conversation.inbox.captain_assistant

    return unless initial_language_eligibility_pending?(conversation, assistant)

    updated_additional_attributes = conversation.additional_attributes.except(Captain::Assistant::LANGUAGE_ELIGIBILITY_PENDING_KEY)
    return handoff_unavailable_captain(conversation, updated_additional_attributes) unless conversation.inbox.captain_active?

    # Language detection completes the initial audience decision asynchronously.
    # Later messages in an already handled conversation do not re-run eligibility.
    if assistant.engages?(conversation.contact, conversation)
      conversation.update!(additional_attributes: updated_additional_attributes)
      Captain::Conversation::ResponseSchedulerService.new(message: message).perform
    else
      conversation.update!(status: :open, additional_attributes: updated_additional_attributes)
    end
  end

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    assistant = conversation.inbox.captain_assistant

    return unless conversation.inbox.captain_active?

    Captain::Llm::ContactNotesService.new(assistant, conversation).generate_and_update_notes if assistant.config['feature_memory'].present?
    Captain::Llm::ConversationFaqJob.perform_later(conversation, assistant) if assistant.config['feature_faq'].present?
  end

  private

  def initial_language_eligibility_pending?(conversation, assistant)
    assistant&.uses_conversation_language? &&
      conversation.additional_attributes[Captain::Assistant::LANGUAGE_ELIGIBILITY_PENDING_KEY] &&
      conversation.pending? &&
      conversation.assignee_agent_bot.blank?
  end

  def handoff_unavailable_captain(conversation, additional_attributes)
    conversation.bot_handoff!
    conversation.update!(additional_attributes: additional_attributes)
  end
end
