class Conversations::UnreadCounts::BroadcastScope
  attr_reader :event

  def initialize(event)
    @event = event
  end

  def perform
    return [conversation.account, conversation.inbox.members] if conversation.present?

    deleted_conversation_scope
  end

  private

  def conversation
    event.data[:conversation]
  end

  def deleted_conversation_scope
    conversation_data = event.data[:conversation_data]&.with_indifferent_access
    return if conversation_data.blank?

    account = Account.find_by(id: conversation_data[:account_id])
    return if account.blank?

    [account, inbox_members_for(account, conversation_data[:inbox_id])]
  end

  def inbox_members_for(account, inbox_id)
    inbox = account.inboxes.find_by(id: inbox_id)
    return User.none if inbox.blank?

    inbox.members
  end
end
