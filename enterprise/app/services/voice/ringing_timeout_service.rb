# Ends an inbound call that has rung for longer than it may: a WhatsApp call past Meta's own
# ring, found by the sweep, or a Twilio call past the inbox's ring time, run by the job queued
# for it as the ring starts. Nothing else moves such a call on: the web keeps a ringing card,
# phones keep their ring, and the missed call is never recorded.
class Voice::RingingTimeoutService
  pattr_initialize [:call!]

  # Meta's carrier ring lasts up to about 60 s, so a call is never ended here while the
  # caller still hears it ring. A Twilio caller waits on the conference's music until they
  # hang up or an agent joins, unless the inbox ends unanswered calls after its own ring time.
  RING_TIMEOUT_SECONDS = { 'whatsapp' => 60 }.freeze
  # A timeout attempt older than this is taken to have died, and another may start
  ATTEMPT_TTL_SECONDS = 120

  # Inbound calls still ringing past their provider's timeout that rang phones, as the
  # agents rung recorded on the call show, so one stays covered if the account stops
  # ringing phones meanwhile. A WhatsApp answer moves the call on as it is claimed, so a
  # ringing call has no claim. An outbound call ends with the provider's own word.
  def self.overdue
    RING_TIMEOUT_SECONDS.map { |provider, seconds| Call.where(status: 'ringing', provider: provider).where(created_at: ...seconds.seconds.ago) }
                        .reduce(:or)
                        .where(direction: :incoming)
                        .where("calls.ring_state ? 'ring_recipient_ids'")
  end

  # The call is marked as timing out under the row lock, so another attempt, and the
  # provider's own status for the hang-up, leave the call alone while the mark is fresh; agent
  # claims are refused meanwhile, see ConferenceService#claim_call!. A Twilio caller is then
  # moved out of the conference to the no-answer announcement. The call is ended only if nobody
  # answered; one answered meanwhile has this attempt's mark cleared. A failure before the caller
  # is moved clears the mark so an agent can still answer; one after keeps it, so claims stay
  # refused until the retry, which waits out the mark, records the missed call.
  # Returns the seconds to wait when an agent's connection is still on its way in, or another
  # attempt's mark is still fresh (its worker may have died), else nil.
  def perform
    started = start_timeout
    return started unless started == true

    caller_gone = begin
      caller_gone?
    rescue StandardError
      call.with_lock { clear_timeout_mark if call.ring_state['timing_out_at'] == @attempt_at }
      raise
    end
    call.with_lock do
      next unless call.ring_state['timing_out_at'] == @attempt_at

      caller_gone && unanswered? ? finalize : clear_timeout_mark
    end
    nil
  end

  private

  # An agent connection still on its way in is given its time to join first
  def start_timeout
    call.with_lock do
      next unless call.ringing? && call.incoming? && due?

      wait = call.ring_timeout_wait || call.agent_leg_join_wait
      next wait if wait

      @attempt_at = Time.zone.now.to_i
      call.update_columns(ring_state: call.ring_state.merge('timing_out_at' => @attempt_at)) # rubocop:disable Rails/SkipsModelValidations
      true
    end
  end

  # Meta's ring is bounded by the sweep's clock; a Twilio ring by the job queued for it
  def due?
    return call.inbox.channel.unanswered_calls_enabled? if call.twilio?

    timeout = RING_TIMEOUT_SECONDS[call.provider]
    timeout.present? && call.created_at < timeout.seconds.ago
  end

  # Whether the caller is gone. A WhatsApp caller has given up already. A Twilio caller is
  # redirected to the announcement and hung up, unless they hung up just before (Twilio 21220,
  # not in progress); an agent Twilio shows on the call keeps it, since the join webhook that
  # would have moved it on may have been lost.
  def caller_gone?
    return true unless call.twilio?
    return false if Voice::Provider::Twilio::ConferenceService.new(call: call).agents_remain?(leaving_call_sid: nil)

    twiml = Voice::Provider::Twilio::TwimlBuilder.new(inbox: call.inbox).announcement(:unanswered)
    call.inbox.channel.client.calls(call.provider_call_id).update(twiml: twiml)
    true
  rescue Twilio::REST::RestError => e
    raise unless e.code == 21_220 || e.status_code == 404

    true
  end

  # Moving a Twilio caller out makes their leave and the conference's end reach the row within
  # moments, possibly as completed with no agent on it, or claimed by one whose leg never
  # joined; the ring time's outcome still stands
  def unanswered?
    call.ringing? || (call.twilio? && !call.answered_by_agent?)
  end

  def clear_timeout_mark
    call.update_columns(ring_state: call.ring_state.except('timing_out_at')) # rubocop:disable Rails/SkipsModelValidations
  end

  def finalize
    call.update!(status: 'no_answer', end_reason: Call::RING_TIMEOUT, meta: (call.meta || {}).merge('ended_at' => Time.zone.now.to_i))
    Voice::CallMessageBuilder.new(call).update_status!(status: 'no_answer')
    call.conversation.update!(
      additional_attributes: (call.conversation.additional_attributes || {}).merge('call_status' => call.display_status)
    )
    call.broadcast_voice_call_event(:ended, status: call.display_status)
  end
end
