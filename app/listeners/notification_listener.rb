class NotificationListener < BaseListener
  def conversation_bot_handoff(event)
    conversation, account = extract_conversation_and_account(event)
    return if conversation.pending?

    conversation.inbox.members.each do |agent|
      NotificationBuilder.new(
        notification_type: 'conversation_creation',
        user: agent,
        account: account,
        primary_actor: conversation
      ).perform
    end
  end

  def conversation_created(event)
    conversation, account = extract_conversation_and_account(event)
    return if conversation.pending?

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

    # NOTE:  The issue was that when a team change results in an assignee being set to nil,
    # the system was still trying to create a notification about the assignment change,
    # but there was no assignee to notify, causing potential issues in the notification system.
    # We need to debug this properly, but for now no need to pollute the jobs
    return if assignee.blank?
    return if event.data[:notifiable_assignee_change].blank?
    return if conversation.pending?

    NotificationBuilder.new(
      notification_type: 'conversation_assignment',
      user: assignee,
      account: account,
      primary_actor: conversation
    ).perform
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]

    Messages::MentionService.new(message: message).perform
    Messages::NewMessageNotificationService.new(message: message).perform
  end

  def message_reaction_created(event)
    message_reaction = event.data[:message_reaction]
    conversation = event.data[:conversation]
    account = event.data[:account]

    notify_conversation_assignee(message_reaction, conversation, account)
    notify_participating_users(message_reaction, conversation, account)
  end

  def message_reaction_updated(event)
    return unless event.data[:message_reaction]&.active?

    message_reaction_created(event)
  end

  private

  def notify_conversation_assignee(message_reaction, conversation, account)
    assignee = conversation.assignee
    return if assignee.blank?
    return if reaction_from?(message_reaction, assignee)

    NotificationBuilder.new(
      notification_type: 'assigned_conversation_message_reaction',
      user: assignee,
      account: account,
      primary_actor: conversation,
      secondary_actor: message_reaction
    ).perform
  end

  def notify_participating_users(message_reaction, conversation, account)
    participating_users = conversation.conversation_participants.map(&:user)
    participating_users -= [conversation.assignee]

    participating_users.uniq.each do |participant|
      next if reaction_from?(message_reaction, participant)

      NotificationBuilder.new(
        notification_type: 'participating_conversation_message_reaction',
        user: participant,
        account: account,
        primary_actor: conversation,
        secondary_actor: message_reaction
      ).perform
    end
  end

  def reaction_from?(message_reaction, agent)
    message_reaction.sender_type == 'User' && message_reaction.sender_id == agent.id
  end
end
