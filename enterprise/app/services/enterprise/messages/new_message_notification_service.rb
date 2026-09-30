module Enterprise::Messages::NewMessageNotificationService
  def perform
    return if replaced_by_missed_call_notification?

    super
  end

  private

  # Where phones are rung for a call, the ring itself and the missed-call notification
  # stand in for the new-message notification
  def replaced_by_missed_call_notification?
    message.voice_call? && message.account.feature_enabled?('mobile_voice_push')
  end
end
