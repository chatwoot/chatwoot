# Resolves conversations that have been sitting in the `pending` status with no
# activity for longer than the account's `auto_resolve_pending_after` setting.
#
# `Conversations::ResolutionJob` only handles `open` conversations. Pending
# conversations (typically ones a bot could not hand off) would otherwise stay
# pending forever and pollute the pending folder and the reports.
class Conversations::PendingResolutionJob < ApplicationJob
  queue_as :low

  def perform(account:)
    # limiting the number of conversations to be resolved to avoid any performance issues
    resolvable_conversations = conversation_scope(account).limit(Limits::BULK_ACTIONS_LIMIT)
    resolvable_conversations.each do |conversation|
      ::MessageTemplates::Template::AutoResolvePending.new(conversation: conversation).perform if account.auto_resolve_pending_message.present?
      conversation.resolved!
    end
  end

  private

  def conversation_scope(account)
    # Exclude orphan conversations where contact was deleted but conversation cleanup is pending
    account.conversations.resolvable_pending(account.auto_resolve_pending_after).where.not(contact_id: nil)
  end
end
