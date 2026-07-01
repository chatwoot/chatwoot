class CaptainListener < BaseListener
  include ::Events::Types

  def message_created(event)
    message = extract_message_and_account(event)[0]

    if message.incoming?
      if message.account.feature_enabled?('sentiment_analysis')
        Messages::DetectSentimentJob.perform_later(message.id)
      end

      if message.account.feature_enabled?('auto_categorization') && message.conversation.messages.incoming.count == 3
        Conversations::AutoCategorizeJob.perform_later(message.conversation_id)
      end
    end
  end

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    assistant = conversation.inbox.captain_assistant

    if conversation.account.feature_enabled?('ai_resolution_tracking')
      Conversations::EvaluateAiResolutionJob.perform_later(conversation.id)
    end

    if conversation.account.feature_enabled?('auto_qa')
      Conversations::EvaluateAutoQaJob.perform_later(conversation.id)
    end

    return unless conversation.inbox.captain_active?

    Captain::Llm::ContactNotesService.new(assistant, conversation).generate_and_update_notes if assistant.config['feature_memory'].present?
    Captain::Llm::ConversationFaqService.new(assistant, conversation).generate_and_deduplicate if assistant.config['feature_faq'].present?
  end
end
