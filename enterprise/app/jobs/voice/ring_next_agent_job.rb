# Widens the ring of a Twilio call every step while it rings, so an agent who comes online
# meanwhile is reached too, as is a call that found nobody to ring. A call that rings in turn
# adds the next agent; one that rings everyone at once adds the team, which an assignee
# ringing alone leads to, and then the agents it held back. A dismiss runs the next step at once, and a job for a step it
# already moved past does nothing. A call an agent is picking up adds nobody, and rings on
# should their connection fail.
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

  def agents_to_add(call, rung)
    return [] if call.accepted_by_agent_id.present?

    recipients = Voice::RingRecipients.new(inbox: call.inbox, conversation: call.conversation, dismissed_user_ids: call.dismissed_user_ids)
    return [recipients.next_agent(rung)].compact if call.inbox.channel.sequential_ringing?

    recipients.next_group(rung)
  end

  def queue_next_step(call, step)
    return unless call.created_at > MAX_RING_SECONDS.seconds.ago

    self.class.set(wait: call.inbox.channel.ring_step_seconds.seconds).perform_later(call.id, step + 1)
  end
end
