class CaptainListener < BaseListener
  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    account = conversation.account
    inbox = conversation.inbox

    return unless conversation.inbox.captain_active?

    generate_notes(assistant, conversation) if assistant.config['feature_memory'].present?
    generate_faqs(assistant, conversation) if assistant.config['feature_faq'].present?
  end

  private

  def generate_notes(assistant, conversation)
    Captain::Llm::ContactNotesService.new(assistant, conversation).generate_and_update_notes

    account = conversation.account
    Rails.logger.info("[CAPTAIN][ContactNotesService] Incrementing response usage for #{account.id}")
    account.increment_response_usage
  end

  def generate_faqs(assistant, conversation)
    Captain::Llm::ConversationFaqService.new(assistant, conversation).generate_and_deduplicate

    account = conversation.account
    Rails.logger.info("[CAPTAIN][ConversationFaqService] Incrementing response usage for #{account.id}")
    account.increment_response_usage
  end
end
