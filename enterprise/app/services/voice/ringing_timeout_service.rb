# Ends a call that has rung for longer than its provider gives it. Nothing else moves a
# ringing call on when the provider's own end-of-ring never arrives: the web keeps a
# ringing card, phones keep their ring, and the missed call is never recorded.
class Voice::RingingTimeoutService
  pattr_initialize [:call!]

  # Meta's carrier ring lasts up to about 60 s; Twilio rings until the caller gives up. The
  # window is the provider's own, so a call is never ended here while the caller still hears it ring
  RING_TIMEOUT_SECONDS = { 'twilio' => 60, 'whatsapp' => 60 }.freeze
  # A claim normally turns into a joined call within seconds; one still ringing this long
  # past the timeout was abandoned (the agent's join failed or the tab closed)
  CLAIM_GRACE_SECONDS = 60
  # A timeout attempt older than this is taken to have died, and another may start
  ATTEMPT_TTL_SECONDS = 120

  # Inbound calls still ringing past their provider's timeout, unclaimed or with an
  # abandoned claim, on the accounts that ring phones. An outbound call ends with the
  # provider's own word.
  def self.overdue
    RING_TIMEOUT_SECONDS.flat_map do |provider, seconds|
      ringing = Call.where(status: 'ringing', provider: provider)
      [ringing.where(accepted_by_agent_id: nil, created_at: ...seconds.seconds.ago),
       ringing.where.not(accepted_by_agent_id: nil).where(created_at: ...(seconds + CLAIM_GRACE_SECONDS).seconds.ago)]
    end.reduce(:or).where(direction: :incoming).where(account_id: Account.feature_mobile_voice_push.select(:id))
  end

  # The call is marked as timing out under the row lock, which an agent's claim checks, so
  # a claim made from here on is refused, and another sweep leaves the call alone while
  # the mark is fresh. The caller is hung up outside the lock, so the webhooks the hang-up
  # triggers do not wait on it. The call is ended only once the caller has been hung up
  # and no claim has changed since the mark; otherwise this attempt's mark is cleared and
  # the next sweep tries again.
  def perform
    return unless start_timeout

    hung_up = hang_up_caller
    call.with_lock do
      next unless call.ring_state['timing_out_at'] == @attempt_at

      if hung_up && call.ringing? && call.accepted_by_agent_id == @claim_at_start
        finalize
      else
        clear_timeout_mark
      end
    end
  end

  private

  def start_timeout
    call.with_lock do
      next false unless call.ringing? && call.incoming? && due? && !attempt_in_progress?

      @attempt_at = Time.zone.now.to_i
      @claim_at_start = call.accepted_by_agent_id
      call.update_columns(ring_state: call.ring_state.merge('timing_out_at' => @attempt_at)) # rubocop:disable Rails/SkipsModelValidations
      true
    end
  end

  def due?
    grace = call.accepted_by_agent_id ? CLAIM_GRACE_SECONDS : 0
    call.created_at < (RING_TIMEOUT_SECONDS.fetch(call.provider, 60) + grace).seconds.ago
  end

  def attempt_in_progress?
    started_at = call.ring_state['timing_out_at']
    started_at.present? && started_at > ATTEMPT_TTL_SECONDS.seconds.ago.to_i
  end

  def clear_timeout_mark
    call.update_columns(ring_state: call.ring_state.except('timing_out_at')) # rubocop:disable Rails/SkipsModelValidations
  end

  # A Twilio caller is still waiting for the conference to start; Meta has already given up
  def hang_up_caller
    return true unless call.twilio?

    Voice::Provider::Twilio::ConferenceService.new(call: call).terminate_call
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
