class Captain::Llm::ConversationFaqJob < MutexApplicationJob
  queue_as :low

  LOCK_TIMEOUT = 10.minutes

  retry_on_lock_conflict wait: 30.seconds, attempts: 30

  def perform(conversation, assistant)
    inbox = conversation.inbox

    return unless conversation.resolved?
    return unless inbox.captain_active?

    return if assistant.config['feature_faq'].blank?

    with_lock(lock_key(assistant, conversation), LOCK_TIMEOUT) do
      Captain::Llm::ConversationFaqService.new(assistant, conversation).generate_suggestions
    end
  end

  private

  def lock_key(assistant, conversation)
    format(
      ::Redis::Alfred::CAPTAIN_CONVERSATION_FAQ_MUTEX,
      assistant_id: assistant.id,
      language: Captain::Llm::ConversationFaqService.language_for(conversation)
    )
  end
end
