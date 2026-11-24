module Enterprise::Messages::NewMessageNotificationService
  # The message job and push completion both notify; the lock prevents duplicate notifications.
  def perform
    return super unless message.voice_call?

    message.with_lock { super }
  end

  private

  def already_notified?(user)
    super || rung_for_call?(user)
  end

  # The recorded ring audience remains authoritative if the feature is disabled mid-call.
  def rung_for_call?(user)
    return false unless message.voice_call?

    rung_user_ids.include?(user.id) && missed_call_delivered?(user)
  end

  def missed_call_delivered?(user)
    setting = user.notification_settings.find_by(account_id: message.account_id)
    setting.present? && (setting.push_voice_call_missed? || setting.email_voice_call_missed?)
  end

  # Empty while the message is not linked to its call yet, for a call that has not entered
  # the ring, or for one that does not ring phones: until the ring is known to reach
  # someone, everyone keeps the notification
  def rung_user_ids
    @rung_user_ids ||= begin
      call = Call.find_by(message_id: message.id)
      rings_phones = call&.ring_state&.key?('ring_recipient_ids') && call.ring_state['rings_phones'] != false
      rings_phones ? Voice::VoipPushService.new(call: call).ringable_user_ids : []
    end
  end
end
