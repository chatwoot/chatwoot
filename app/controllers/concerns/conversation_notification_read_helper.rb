module ConversationNotificationReadHelper
  private

  # Bulk mark read (same pattern as Api::V1::Accounts::NotificationsController#read_all).
  # Skips per-row callbacks to avoid N writes + N after_update_commit dispatches on a hot path.
  def mark_conversation_notifications_read
    return unless Current.user.is_a?(User)

    # rubocop:disable Rails/SkipsModelValidations
    current_user.notifications.where(
      account_id: Current.account.id,
      primary_actor: @conversation,
      read_at: nil
    ).update_all(read_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
