# Widens the ring of a Twilio call every interval, so agents who come online meanwhile are
# reached. Each run carries the step it was queued for; a dismiss moves the step on, so a job
# for a step already passed does nothing.
class Voice::RingNextAgentJob < ApplicationJob
  queue_as :critical

  # Steps stop after the longest ring time an inbox can set, so a call whose end was never
  # reported does not step forever
  MAX_RING_SECONDS = 300

  def perform(call_id, step)
    call = Call.find_by(id: call_id)
    return if call.blank?

    added = call.with_lock do
      next unless call.ringing? && call.ring_step == step

      add_agents(call, step)
    end
    return if added.nil?

    # Queued first, so a push that fails does not stop the ring widening
    queue_next_step(call, step)
    Voice::AddedRingPushService.new(call: call, users: added).perform if added.any? && call.ring_state['rings_phones'] != false
  end

  private

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
    return unless call.created_at > MAX_RING_SECONDS.seconds.ago

    self.class.set(wait: call.inbox.channel.ring_step_seconds.seconds).perform_later(call.id, step + 1)
  end
end
