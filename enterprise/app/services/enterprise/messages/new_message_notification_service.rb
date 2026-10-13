module Enterprise::Messages::NewMessageNotificationService
  # A call message is notified by its own job and again once its ring settles. Both run
  # under the message's row lock, so the later one sees what the earlier one created.
  def perform
    return super unless message.voice_call?

    message.with_lock { super }
  end

  private

  def already_notified?(user)
    super || rung_for_call?(user)
  end

  # Where phones are rung for a call, the agents whose phone the ring reaches, and who get
  # missed calls by push or email, get those in place of the new-message notification;
  # anyone else, such as an assignee who is busy or has no phone that can ring, keeps it
  def rung_for_call?(user)
    return false unless message.voice_call? && message.account.feature_enabled?('mobile_voice_push')

    rung_user_ids.include?(user.id) && missed_call_delivered?(user)
  end

  def missed_call_delivered?(user)
    setting = user.notification_settings.find_by(account_id: message.account_id)
    setting.present? && (setting.push_voice_call_missed? || setting.email_voice_call_missed?)
  end

  # Empty while the message is not linked to its call yet, or for a call that has not
  # entered the ring: until the ring is known to reach someone, everyone keeps the
  # notification
  def rung_user_ids
    @rung_user_ids ||= begin
      call = Call.find_by(message_id: message.id)
      call&.ring_state&.key?('ring_recipient_ids') ? Voice::VoipPushService.new(call: call).ringable_user_ids : []
    end
  end
end
