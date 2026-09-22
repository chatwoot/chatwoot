# Ends a call that has rung for longer than its provider gives it. Nothing else moves a
# ringing call on when the provider's own end-of-ring never arrives: the web keeps a
# ringing card, phones keep their ring, and the missed call is never recorded.
class Voice::RingingTimeoutService
  pattr_initialize [:call!]

  # Meta drops an unanswered call after 30 to 60 s; Twilio rings until the caller gives up
  RING_TIMEOUT_SECONDS = { 'twilio' => 60, 'whatsapp' => 45 }.freeze

  # Calls still ringing past their provider's timeout
  def self.overdue
    RING_TIMEOUT_SECONDS.map { |provider, seconds| Call.where(status: 'ringing', provider: provider).where(created_at: ...seconds.seconds.ago) }
                        .reduce(:or)
  end

  def perform
    return unless call.account.feature_enabled?('mobile_voice_push')

    call.with_lock do
      next unless call.ringing?

      hang_up_caller
      finalize
    end
  end

  private

  # A Twilio caller is still parked in the conference; Meta has already given up
  def hang_up_caller
    return unless call.twilio?

    Voice::Provider::Twilio::ConferenceService.new(call: call).end_conference
  rescue StandardError => e
    Rails.logger.error("[VOICE] ring timeout call #{call.id}: could not end conference: #{e.class}: #{e.message}")
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
