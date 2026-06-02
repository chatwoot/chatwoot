class Conversations::ResolutionJob < ApplicationJob
  queue_as :low

  def perform(account:)
    # limiting the number of conversations to be resolved to avoid any performance issues
    resolvable_conversations = conversation_scope(account).limit(Limits::BULK_ACTIONS_LIMIT)
    resolvable_conversations.each do |conversation|
      # send message from bot that conversation has been resolved
      # do this is account.auto_resolve_message is set
      ::MessageTemplates::Template::AutoResolve.new(conversation: conversation).perform if account.auto_resolve_message.present?
      conversation.add_labels(account.auto_resolve_label) if account.auto_resolve_label.present?
      conversation.toggle_status
    end
  end

  private

  def conversation_scope(account)
    base_scope = if account.auto_resolve_ignore_waiting
                   account.conversations.resolvable_not_waiting(account.auto_resolve_after)
                 else
                   account.conversations.resolvable_all(account.auto_resolve_after)
                 end
    # Exclude orphan conversations where contact was deleted but conversation cleanup is pending
    base_scope.where.not(contact_id: nil)
  end
end
