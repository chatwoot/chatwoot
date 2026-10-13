# Ends a WhatsApp call that has rung for longer than Meta gives it. Nothing else moves such
# a call on when Meta's own end-of-ring never arrives: the web keeps a ringing card, phones
# keep their ring, and the missed call is never recorded.
class Voice::RingingTimeoutService
  pattr_initialize [:call!]

  # Meta's carrier ring lasts up to about 60 s, so a call is never ended here while the
  # caller still hears it ring. A Twilio caller waits on hold music until they hang up or
  # an agent joins, as on the web, so Twilio calls have no timeout here.
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

  # The call is marked as timing out under the row lock, so another sweep, and the
  # provider's own status for the hang-up, leave the call alone while the mark is fresh.
  # The call is ended only if it is still ringing; one answered meanwhile has this
  # attempt's mark cleared.
  def perform
    return unless start_timeout

    call.with_lock do
      next unless call.ring_state['timing_out_at'] == @attempt_at

      if call.ringing?
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
      call.update_columns(ring_state: call.ring_state.merge('timing_out_at' => @attempt_at)) # rubocop:disable Rails/SkipsModelValidations
      true
    end
  end

  def due?
    timeout = RING_TIMEOUT_SECONDS[call.provider]
    timeout.present? && call.created_at < timeout.seconds.ago
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
