# Ends a WhatsApp call that has rung for longer than Meta gives it. Nothing else moves such
# a call on when Meta's own end-of-ring never arrives: the web keeps a ringing card, phones
# keep their ring, and the missed call is never recorded.
class Voice::RingingTimeoutService
  pattr_initialize [:call!]

  # Meta's carrier ring lasts up to about 60 s, so a call is never ended here while the
  # caller still hears it ring. A Twilio caller waits on hold music until they hang up or
  # an agent joins, as on the web, so Twilio calls have no timeout here.
  RING_TIMEOUT_SECONDS = { 'whatsapp' => 60 }.freeze
  # A claim normally turns into a joined call within seconds; one still ringing this long
  # past the timeout was abandoned (the agent's join failed or the tab closed)
  CLAIM_GRACE_SECONDS = 60
  # When a call was claimed; a claim without a recorded time counts from when the call started
  CLAIMED_AT_SQL = "COALESCE((calls.ring_state->>'claimed_at')::bigint, EXTRACT(EPOCH FROM calls.created_at)::bigint)".freeze
  # A timeout attempt older than this is taken to have died, and another may start
  ATTEMPT_TTL_SECONDS = 120

  # Inbound calls still ringing past their provider's timeout, unclaimed or with an
  # abandoned claim, that rang phones: on the accounts that ring them, with the agents
  # rung recorded. An outbound call ends with the provider's own word.
  def self.overdue
    RING_TIMEOUT_SECONDS.map { |provider, seconds| Call.where(status: 'ringing', provider: provider).where(created_at: ...seconds.seconds.ago) }
                        .reduce(:or)
                        .where(direction: :incoming)
                        .where("calls.accepted_by_agent_id IS NULL OR #{CLAIMED_AT_SQL} < ?", CLAIM_GRACE_SECONDS.seconds.ago.to_i)
                        .where(account_id: Account.feature_mobile_voice_push.select(:id))
                        .where("calls.ring_state ? 'ring_recipient_ids'")
  end

  # The call is marked as timing out under the row lock, which an agent's claim checks, so
  # a claim made from here on is refused, and another sweep leaves the call alone while
  # the mark is fresh. The call is ended only if no claim has changed since the mark;
  # otherwise this attempt's mark is cleared and the next sweep tries again.
  def perform
    return unless start_timeout

    call.with_lock do
      next unless call.ring_state['timing_out_at'] == @attempt_at

      if call.ringing? && call.accepted_by_agent_id == @claim_at_start
        finalize
      else
        clear_timeout_mark
      end
    end
  end

  private

  def start_timeout
    call.with_lock do
      next false unless call.ringing? && call.incoming? && due? && !call.ring_timeout_in_progress?

      @attempt_at = Time.zone.now.to_i
      @claim_at_start = call.accepted_by_agent_id
      call.update_columns(ring_state: call.ring_state.merge('timing_out_at' => @attempt_at)) # rubocop:disable Rails/SkipsModelValidations
      true
    end
  end

  # Rung past its provider's timeout, and either unclaimed or claimed long enough ago that
  # the join was abandoned
  def due?
    timeout = RING_TIMEOUT_SECONDS[call.provider]
    return false unless timeout && call.created_at < timeout.seconds.ago
    return true if call.accepted_by_agent_id.nil?

    (call.ring_state['claimed_at'] || call.created_at.to_i) < CLAIM_GRACE_SECONDS.seconds.ago.to_i
  end

  def clear_timeout_mark
    call.update_columns(ring_state: call.ring_state.except('timing_out_at')) # rubocop:disable Rails/SkipsModelValidations
  end

  # A Twilio caller is still waiting for the conference to start; Meta has already given up
  def finalize
    call.update!(status: 'no_answer', end_reason: 'ring_timeout', meta: (call.meta || {}).merge('ended_at' => Time.zone.now.to_i))
    Voice::CallMessageBuilder.new(call).update_status!(status: 'no_answer')
    call.conversation.update!(
      additional_attributes: (call.conversation.additional_attributes || {}).merge('call_status' => call.display_status)
    )
    call.broadcast_voice_call_event(:ended, status: call.display_status)
  end
end
