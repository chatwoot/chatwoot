class CaptainListener < BaseListener
  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    assistant = conversation.inbox.captain_assistant

    return unless assistant.present?

    Captain::Llm::ContactNotesService.new(assistant, conversation).generate_and_update_notes if assistant.config['feature_memory'].present?
    # TODO: Implement the faq feature and enable this
    # Captain::Llm::FaqGeneratorService.new(conversation.content).generate if assistant.config['feature_faq'].present?
  end
end
