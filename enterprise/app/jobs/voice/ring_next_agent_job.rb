# Widens the ring of an inbound call, Twilio or WhatsApp, every interval, so agents who come online meanwhile are
# reached. Each run carries the step it was queued for; a dismiss moves the step on, so a job
# for a step already passed does nothing.
class Voice::RingNextAgentJob < ApplicationJob
  queue_as :critical

  # Steps go on until the call stops ringing, or at the latest Twilio's default four-hour dial
  # limit, never forever for a call whose end was never reported. Meta ends a WhatsApp ring itself
  # after about a minute.
  MAX_RING_SECONDS = 4.hours.to_i

  def perform(call_id, step)
    call = Call.find_by(id: call_id)
    return if call.blank?

    added = widen_ring(call, step)
    return if added.nil?

    Voice::AddedRingPushService.new(call: call, users: added).perform if added.any? && call.ring_state['rings_phones'] != false
    # A call still ringing past the dial limit lost its end callback, so it no longer holds off its
    # conversation's auto-assignment (see Concerns::CallAssignmentHold), which runs here instead
    call.conversation.auto_assign_after_call if dial_ended?(call)
  end

  private

  # The next step is queued under the lock that moves the step on, so a failed enqueue rolls
  # the move back and the retry runs this step again; a push that fails then stops nothing
  def widen_ring(call, step)
    call.with_lock do
      next unless call.ringing? && call.ring_step == step

      add_agents(call, step).tap { queue_next_step(call, step) unless dial_ended?(call) }
    end
  end

  # Read once per step, so a step either queues the next one or runs the held assignment, never both
  def dial_ended?(call)
    @dial_ended = call.created_at <= MAX_RING_SECONDS.seconds.ago unless defined?(@dial_ended)
    @dial_ended
  end

  # Called under the row lock, which the end of the call also takes, so the status on the
  # call's message is never written back to ringing
  def add_agents(call, step)
    rung = call.ring_state.fetch('ring_recipient_ids', [])
    added = agents_to_add(call, rung)
    call.update!(ring_state: call.ring_state.merge('ring_step' => step + 1, 'ring_recipient_ids' => rung + added.map(&:id)))
    Voice::CallMessageBuilder.new(call).update_ring! if added.any?
    added
  end

  # A call an agent is picking up, or the ring timeout is ending, rings no one new but keeps
  # stepping, in case that connection or the timeout fails and the call rings on
  def agents_to_add(call, rung)
    return [] if call.accepted_by_agent_id.present? || call.ring_timeout_in_progress?

    recipients = Voice::RingRecipients.new(inbox: call.inbox, conversation: call.conversation, dismissed_user_ids: call.dismissed_user_ids)
    return [recipients.next_agent(rung)].compact if call.inbox.channel.sequential_ringing?

    recipients.next_group(rung)
  end

  def queue_next_step(call, step)
    self.class.set(wait: call.inbox.channel.ring_step_seconds.seconds).perform_later(call.id, step + 1)
  end
end
