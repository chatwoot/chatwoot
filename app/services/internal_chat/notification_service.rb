class InternalChat::NotificationService
  pattr_initialize [:message!]

  def perform
    channel_members_to_notify.each do |member|
      next if member.user_id == message.sender_id

      notify_member(member)
    end
  end

  private

  def channel_members_to_notify
    message.channel.channel_members
           .where(user_id: FeatureAccess.new(message.account).users_with('internal_chat.access').select(:id))
           .includes(:user)
  end

  def mentioned_user_ids
    @mentioned_user_ids ||= if message.content.present?
                              message.content.scan(%r{\(mention://user/(\d+)/(.+?)\)}).map(&:first).uniq.map(&:to_i)
                            else
                              []
                            end
  end

  def user_mentioned?(user_id)
    mentioned_user_ids.include?(user_id) || (message.content&.include?('@all') && sender_is_admin?)
  end

  def sender_is_admin?
    account_user = message.account.account_users.find_by(user_id: message.sender_id)
    account_user&.administrator? || message.channel.channel_members.exists?(user_id: message.sender_id, role: :admin)
  end

  # Mentions always notify (even when muted); DMs notify unless muted; regular channel
  # messages don't create a native notification (the per-channel unread badge covers them).
  def notify_member(member)
    if user_mentioned?(member.user_id)
      create_notification(member.user, 'internal_chat_mention')
    elsif message.channel.dm? && !member.muted?
      create_notification(member.user, 'internal_chat_new_message')
    end
  end

  def create_notification(user, notification_type)
    NotificationBuilder.new(
      notification_type: notification_type,
      user: user,
      account: message.account,
      primary_actor: message.channel,
      secondary_actor: message
    ).perform
  end
end
