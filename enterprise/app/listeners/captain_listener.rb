class CaptainListener < BaseListener
  include ::Events::Types

  def conversation_created(event)
    conversation = extract_conversation_and_account(event)[0]
    trigger_workflows(conversation, 'conversation_created')
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    return unless message.conversation

    trigger_workflows(message.conversation, 'message_created', message: message)
  end

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    assistant = conversation.inbox.captain_assistant

    return unless conversation.inbox.captain_active?

    Captain::Llm::ContactNotesService.new(assistant, conversation).generate_and_update_notes if assistant.config['feature_memory'].present?
    Captain::Llm::ConversationFaqService.new(assistant, conversation).generate_and_deduplicate if assistant.config['feature_faq'].present?

    trigger_workflows(conversation, 'conversation_resolved')
  end

  private

  def trigger_workflows(conversation, event, extra_context = {})
    return unless conversation.inbox.captain_active?

    assistant = conversation.inbox.captain_assistant
    return unless assistant

    workflows = assistant.workflows.enabled.for_event(event)
    workflows.each do |workflow|
      context = {
        account: conversation.account,
        conversation: conversation,
        contact: conversation.contact,
        event: event
      }.merge(extra_context)

      Captain::Workflows::ExecutionJob.perform_later(workflow, context)
    end
  end
end
