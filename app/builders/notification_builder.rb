class NotificationBuilder
  pattr_initialize [:notification_type!, :user!, :account!, :primary_actor!, :secondary_actor]

  def perform
    build_notification
  end

  private

  def current_user
    Current.user
  end

  def user_subscribed_to_notification?
    notification_setting = user.notification_settings.find_by(account_id: account.id)
    # added for the case where an assignee might be removed from the account but remains in conversation
    return false if notification_setting.blank?

    return true if notification_setting.public_send("email_#{notification_type}?")
    return true if notification_setting.public_send("push_#{notification_type}?")

    false
  end

  def build_notification
    # Create conversation_creation notification only if user is subscribed to it
    return if notification_type == 'conversation_creation' && !user_subscribed_to_notification?
    # skip notifications for silenced conversations except for user mentions
    return if silenced_conversation? && notification_type != 'conversation_mention'
    # respect conversation access (inbox/team membership and custom-role permissions)
    return unless user_can_access_conversation?

    user.notifications.create!(
      notification_type: notification_type,
      account: account,
      primary_actor: primary_actor,
      # secondary_actor is secondary_actor if present, else current_user
      secondary_actor: secondary_actor || current_user
    )
  end

  def conversation
    @conversation ||= primary_actor.is_a?(Conversation) ? primary_actor : primary_actor.try(:conversation)
  end

  # blocked contacts, and conversations filtered as newsletters or from blocklisted senders
  def silenced_conversation?
    primary_actor.contact.blocked? || conversation&.sender_filtered?
  end

  def user_can_access_conversation?
    return true if conversation.blank?

    account_user = AccountUser.find_by(account_id: account.id, user_id: user.id)
    return false if account_user.blank?

    ConversationPolicy.new(
      { user: user, account: account, account_user: account_user },
      conversation
    ).show?
  end
end
