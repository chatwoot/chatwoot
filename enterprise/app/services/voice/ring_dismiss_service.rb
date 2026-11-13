# Stops an inbound call ringing for one agent only, Twilio or WhatsApp: the caller keeps waiting and
# the ring moves on to its next step at once
class Voice::RingDismissService
  pattr_initialize [:call!, :user!]

  # The step is moved on under the lock, with the next one queued, so a failed enqueue rolls the
  # dismiss back and it can be retried
  def perform
    call.with_lock do
      next unless call.ringing? && rings_for_user?

      next_step = call.ring_step + 1
      call.update!(ring_state: call.ring_state.merge('dismissed_user_ids' => call.dismissed_user_ids | [user.id], 'ring_step' => next_step))
      Voice::CallMessageBuilder.new(call).update_ring!
      Voice::RingNextAgentJob.perform_later(call.id, next_step)
    end
  end

  private

  def rings_for_user?
    call.ring_state.fetch('ring_recipient_ids', []).include?(user.id) && call.dismissed_user_ids.exclude?(user.id)
  end
end
