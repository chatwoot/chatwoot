# Ends a Twilio call nobody answered within the inbox's ring time: the caller is moved out of
# the conference to the inbox's no-answer announcement and hung up, and the call is recorded
# as missed. Run by Voice::EndUnansweredCallJob once the ring time is up.
class Voice::EndUnansweredCallService
  pattr_initialize [:call!]

  # Returns the seconds to wait when an agent's connection is still on its way in, else nil
  def perform
    marked = mark_timing_out
    return marked unless marked == :marked

    caller_gone = move_caller_out
    call.with_lock do
      next unless call.ring_state['timing_out_at'] == @attempt_at

      caller_gone && call.ringing? ? finalize : clear_mark
    end
    nil
  rescue StandardError
    call.with_lock { clear_mark if call.ring_state['timing_out_at'] == @attempt_at }
    raise
  end

  private

  # The mark refuses agent claims while the caller is moved out; see ConferenceService#claim_call!.
  # Nothing is marked for a call no longer ringing or already being timed out, and an agent
  # connection still on its way in is given its time to join first.
  def mark_timing_out
    call.with_lock do
      next unless call.ringing? && call.incoming? && !call.ring_timeout_in_progress?

      wait = call.agent_leg_join_wait
      next wait if wait

      @attempt_at = Time.zone.now.to_i
      call.update_columns(ring_state: call.ring_state.merge('timing_out_at' => @attempt_at)) # rubocop:disable Rails/SkipsModelValidations
      :marked
    end
  end

  # Whether the caller is gone: redirected to the announcement and hung up, or hung up already
  # (Twilio 21220, not in progress). An agent Twilio shows on the call keeps it, since the join
  # webhook that would have moved it on may have been lost.
  def move_caller_out
    return false if agent_on_call?

    call.inbox.channel.client.calls(call.provider_call_id).update(twiml: announcement_twiml)
    true
  rescue Twilio::REST::RestError => e
    raise unless e.code == 21_220 || e.status_code == 404

    true
  end

  def agent_on_call? = Voice::Provider::Twilio::ConferenceService.new(call: call).agents_remain?(leaving_call_sid: nil)

  def announcement_twiml = Voice::Provider::Twilio::TwimlBuilder.new(inbox: call.inbox).announcement(:unanswered)

  def finalize
    call.update!(end_reason: Call::RING_TIMEOUT)
    Voice::CallStatus::Manager.new(call: call).process_status_update('no_answer', timestamp: Time.zone.now.to_i)
    Voice::CallMessageBuilder.new(call).update_status!(status: 'no_answer')
    call.broadcast_voice_call_event(:ended, status: call.display_status)
  end

  def clear_mark = call.update_columns(ring_state: call.ring_state.except('timing_out_at')) # rubocop:disable Rails/SkipsModelValidations
end
