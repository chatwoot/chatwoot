# Rings the phones of agents a ring in turn adds once it is under way. Their devices join
# those recorded as rung, so the cancel at the end of the ring reaches them too. The record
# of who the first ring reached, and the new-message notification it replays, stay with the
# agents the ring started with: the agents added later were notified as the call began.
class Voice::AddedRingPushService < Voice::VoipPushService
  pattr_initialize [:call!, :users!]

  def perform
    devices = call.with_lock { call.ringing? ? remember_added_ring : nil }
    return if devices.nil?

    apple_results, android_results = deliver_ring(*devices)
    forget_devices(APPLE, gone(apple_results))
    forget_devices(ANDROID, gone(android_results))
    cancel_added(devices.last - gone(android_results)) unless call.reload.ringing?
  end

  private

  # A call that stopped ringing while these pushes were in flight is cancelled on these phones
  # only; the devices recorded as rung stay, so the cancel queued as the ring ended reaches the rest
  def cancel_added(tokens)
    sender = tokens.any? && fcm_sender(*firebase_config)
    return unless sender

    forget_devices(ANDROID, gone(with_rails { sender.deliver(tokens, payloads.cancel_data, 'cancel') }.to_h))
  end

  def recipients = users

  def remember_added_ring
    apple, android = devices_to_ring
    rung = { 'rung_user_ids' => call.ring_state.fetch('rung_user_ids', []) | token_owners.values.uniq }
    if apple.any? || android.any?
      rung['rung_devices'] = { APPLE => rung_devices.fetch(APPLE, []) | apple, ANDROID => rung_devices.fetch(ANDROID, []) | android }
    end
    merge_ring_state(rung)
    [apple, android]
  end
end
