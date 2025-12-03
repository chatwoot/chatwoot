class Conversations::ResolutionJob < ApplicationJob
  queue_as :low

  def perform(account:)
    # limiting the number of conversations to be resolved to avoid any performance issues
    resolvable_conversations = conversation_scope(account).limit(Limits::BULK_ACTIONS_LIMIT)
    resolvable_conversations.each do |conversation|
      # send message from bot that conversation has been resolved
      # do this is account.auto_resolve_message is set
      unless account.auto_resolve_split_reasons
        ::MessageTemplates::Template::AutoResolve.new(conversation: conversation).perform

        conversation.add_labels(account.auto_resolve_label) if account.auto_resolve_label.present?
        conversation.toggle_status
        next
      end

      message_text =
      if account.auto_resolve_split_reasons
        if conversation.waiting_since.present?
          account.auto_resolve_message_agent.presence || "Оператор не выходит на связь"
        else
          account.auto_resolve_message_client.presence || "Клиент не выходит на связь"
        end
      else
        account.auto_resolve_message.presence
      end    

        conversation.messages.create!(
        message_type: :outgoing,
        content: message_text,
        private: false,
        account_id: account.id,
        inbox_id: conversation.inbox_id
      )

      conversation.add_labels(account.auto_resolve_label) if account.auto_resolve_label.present?
      conversation.toggle_status
    end
  end

  private

  def conversation_scope(account)
    if account.auto_resolve_ignore_waiting
      account.conversations.resolvable_not_waiting(account.auto_resolve_after)
    else
      account.conversations.resolvable_all(account.auto_resolve_after)
    end
  end
end
