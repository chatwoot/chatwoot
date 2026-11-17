# Meta offboards a coexistence number from Cloud API when its WhatsApp Business app is registered again or moved to a
# new device. Finishing the app's registration with the connected-products option kept on usually restores it within
# a few minutes (ACCOUNT_RECONNECTED). Otherwise Meta removes our access about 30 minutes later, so admins are warned
# after REMINDER_DELAY, while the app can still restore the connection.
module Whatsapp::CoexistenceOffboarding
  REMINDER_DELAY = 10.minutes
  STATE_EXPIRY = 1.hour

  module_function

  def offboarded(waba_id)
    return if waba_id.blank?

    offboarded_at = Time.current.to_i
    Redis::Alfred.setex(state_key(waba_id), offboarded_at, STATE_EXPIRY)
    Channels::Whatsapp::OffboardedReminderJob.set(wait: REMINDER_DELAY).perform_later(waba_id, offboarded_at)
  end

  def reconnected(waba_id)
    return if waba_id.blank?

    Redis::Alfred.delete(state_key(waba_id))
  end

  # The timestamp tells a repeated offboard apart, so only its own reminder is sent.
  def still_offboarded?(waba_id, offboarded_at)
    Redis::Alfred.get(state_key(waba_id)) == offboarded_at.to_s
  end

  def state_key(waba_id)
    format(Redis::Alfred::WHATSAPP_COEXISTENCE_OFFBOARDED, waba_id: waba_id)
  end
end
