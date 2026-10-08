module Enterprise::Messages::NewMessageNotificationService
  private

  def already_notified?(user)
    super || rung_for_call?(user)
  end

  # Where phones are rung for a call, the agents whose phone the ring reaches get the ring
  # and the missed-call notification in place of the new-message one; anyone else, such as
  # an assignee who is busy or has no phone that can ring, keeps it
  def rung_for_call?(user)
    return false unless message.voice_call? && message.account.feature_enabled?('mobile_voice_push')

    ids = rung_user_ids
    ids.nil? || ids.include?(user.id)
  end

  # nil when the message is not linked to its call yet, which leaves the notification to the ring
  def rung_user_ids
    return @rung_user_ids if defined?(@rung_user_ids)

    call = Call.find_by(message_id: message.id)
    @rung_user_ids = call && Voice::VoipPushService.new(call: call).ringable_user_ids
  end
end
