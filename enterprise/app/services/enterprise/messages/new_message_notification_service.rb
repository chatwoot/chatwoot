module Enterprise::Messages::NewMessageNotificationService
  private

  def already_notified?(user)
    super || rung_for_call?(user)
  end

  # Where phones are rung for a call, the agents rung get the ring and the missed-call
  # notification in place of the new-message one; anyone not rung, such as an assignee who
  # is busy, keeps it
  def rung_for_call?(user)
    return false unless message.voice_call? && message.account.feature_enabled?('mobile_voice_push')

    ids = ring_recipient_ids
    ids.nil? || ids.include?(user.id)
  end

  # The agents recorded when the ring started, or the same choice made now; nil when the
  # message is not linked to its call yet, which leaves the notification to the ring
  def ring_recipient_ids
    return @ring_recipient_ids if defined?(@ring_recipient_ids)

    call = Call.find_by(message_id: message.id)
    @ring_recipient_ids = call && (call.ring_state['ring_recipient_ids'] || Voice::VoipPushService.recipients_for(call).map(&:id))
  end
end
