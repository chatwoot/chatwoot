# Ends a call that has rung for longer than its provider gives it. Nothing else moves a
# ringing call on when the provider's own end-of-ring never arrives: the web keeps a
# ringing card, phones keep their ring, and the missed call is never recorded.
class Voice::RingingTimeoutService
  pattr_initialize [:call!]

  # Meta's carrier ring lasts up to about 60 s; Twilio rings until the caller gives up. The
  # window is the provider's own, so a call is never ended here while the caller still hears it ring
  RING_TIMEOUT_SECONDS = { 'twilio' => 60, 'whatsapp' => 60 }.freeze

  # Calls still ringing past their provider's timeout, on the accounts that ring phones
  def self.overdue
    RING_TIMEOUT_SECONDS.map { |provider, seconds| Call.where(status: 'ringing', provider: provider).where(created_at: ...seconds.seconds.ago) }
                        .reduce(:or)
                        .where(account_id: Account.feature_mobile_voice_push.select(:id))
  end

  # The call is ended only once the caller has been hung up; while Twilio cannot be
  # reached it stays ringing and the next sweep tries again
  def perform
    call.with_lock do
      next unless call.ringing?
      next unless hang_up_caller

      finalize
    end
  end

  private

  # A Twilio caller is still waiting for the conference to start; Meta has already given up
  def hang_up_caller
    return true unless call.twilio?

    Voice::Provider::Twilio::ConferenceService.new(call: call).hang_up_caller
    true
  rescue StandardError => e
    Rails.logger.error("[VOICE] ring timeout call #{call.id}: could not end conference: #{e.class}: #{e.message}")
    false
  end

  def finalize
    call.update!(status: 'no_answer', end_reason: 'ring_timeout', meta: (call.meta || {}).merge('ended_at' => Time.zone.now.to_i))
    Voice::CallMessageBuilder.new(call).update_status!(status: 'no_answer')
    call.conversation.update!(
      additional_attributes: (call.conversation.additional_attributes || {}).merge('call_status' => call.display_status)
    )
    call.broadcast_voice_call_event(:ended, status: call.display_status)
  end
end
