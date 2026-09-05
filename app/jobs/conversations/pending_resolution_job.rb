class Conversations::PendingResolutionJob < ApplicationJob
  queue_as :low

  def perform(account:)
    resolvable = account.conversations
                        .resolvable_pending(account.auto_resolve_pending_after)
                        .where.not(contact_id: nil)
                        .limit(Limits::BULK_ACTIONS_LIMIT)

    resolvable.each do |conversation|
      resolve_pending_conversation(conversation, account)
    end
  end

  private

  def resolve_pending_conversation(conversation, account)
    send_pending_resolve_message(conversation, account)
    conversation.resolved!
  end

  def send_pending_resolve_message(conversation, account)
    message_text = account.auto_resolve_pending_message.presence
    return if message_text.blank?

    if conversation.can_reply?
      conversation.messages.create!(
        message_type: :template,
        content: message_text,
        account_id: account.id,
        inbox_id: conversation.inbox_id
      )
    else
      content = I18n.t('conversations.activity.auto_resolve.not_sent_due_to_messaging_window')
      activity_params = {
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :activity,
        content: content
      }
      ::Conversations::ActivityMessageJob.perform_later(conversation, activity_params) if content
    end
  end
end
