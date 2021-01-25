class NotificationListener < BaseListener
  def conversation_created(event)
    conversation, account = extract_conversation_and_account(event)
    return if conversation.bot?

    conversation.inbox.members.each do |agent|
      NotificationBuilder.new(
        notification_type: 'conversation_creation',
        user: agent,
        account: account,
        primary_actor: conversation
      ).perform
    end
  end

  def assignee_changed(event)
    conversation, account = extract_conversation_and_account(event)
    assignee = conversation.assignee
    return unless conversation.notifiable_assignee_change?
    return if conversation.bot?

    NotificationBuilder.new(
      notification_type: 'conversation_assignment',
      user: assignee,
      account: account,
      primary_actor: conversation
    ).perform
  end

  def message_created(event)
    message, account = extract_message_and_account(event)
    conversation = message.conversation

    generate_notifications_for_mentions(message, account)

    # only want to notify agents about customer messages
    return unless message.incoming?
    return unless conversation.assignee

    NotificationBuilder.new(
      notification_type: 'assigned_conversation_new_message',
      user: conversation.assignee,
      account: account,
      primary_actor: conversation
    ).perform
  end

  private

  def get_valid_mentioned_ids(mentioned_ids, inbox)
    valid_mentionable_ids = inbox.account.administrators.map(&:id) + inbox.members.map(&:id)
    # Intersection of ids
    mentioned_ids & valid_mentionable_ids.uniq.map(&:to_s)
  end

  def generate_notifications_for_mentions(message, account)
    return unless message.private?

    mentioned_ids = message.content.scan(%r{\(mention://(user|team)/(\d+)/([\w\s]+)\)}).map(&:second).uniq
    return if mentioned_ids.blank?

    get_valid_mentioned_ids(mentioned_ids, message.inbox).each do |user_id|
      NotificationBuilder.new(
        notification_type: 'conversation_mention',
        user: User.find(user_id),
        account: account,
        primary_actor: message
      ).perform
    end
  end
end
