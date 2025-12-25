class Conversations::UnreadCountService
  attr_reader :account, :user

  def initialize(account:, user:)
    @account = account
    @user = user
  end

  def perform
    {
      by_inbox: unread_by_inbox,
      by_label: unread_by_label,
      by_status: unread_by_status,
      total: total_unread_count
    }
  end

  private

  def base_conversations
    conversations = account.conversations.with_unread_messages.where(status: %i[open pending])
    Conversations::PermissionFilterService.new(conversations, user, account).perform
  end

  def unread_by_inbox
    base_conversations.group(:inbox_id).count
  end

  def unread_by_label
    base_conversations
      .joins(:taggings)
      .joins('INNER JOIN tags ON tags.id = taggings.tag_id')
      .group('tags.name')
      .count
  end

  def unread_by_status
    conversations = base_conversations
    {
      all: conversations.count,
      mine: conversations.assigned_to(user).count,
      unassigned: conversations.unassigned.count
    }
  end

  def total_unread_count
    base_conversations.count
  end
end

Conversations::UnreadCountService.prepend_mod_with('Conversations::UnreadCountService')
