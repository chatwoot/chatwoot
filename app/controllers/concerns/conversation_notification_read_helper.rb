module ConversationNotificationReadHelper
  private

  def mark_conversation_notifications_read
    return unless Current.user.is_a?(User)

    current_user.notifications.where(
      account_id: Current.account.id,
      primary_actor: @conversation,
      read_at: nil
    ).find_each do |notification|
      notification.update!(read_at: Time.current)
    end
  end
end
