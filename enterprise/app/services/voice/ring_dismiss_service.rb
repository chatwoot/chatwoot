class Voice::RingDismissService
  pattr_initialize [:call!, :user!]

  # Stops the ring for one agent only; the call keeps ringing for the others. The ring then
  # widens at once, past the step the dismiss moved on from: a ring in turn adds the next agent,
  # and one that rang only this agent rings the team. A dismiss by an agent the call does not
  # ring, or a repeated one, changes nothing. The step is queued under the lock that moves it on,
  # so a failed enqueue undoes the dismiss and the agent can retry it; the job waits for the lock.
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
