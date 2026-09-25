# Ends a call's Twilio conference when the request failed at the moment the last agent
# left, so the contact is not left alone until Twilio's own timeout. Given the label of
# the agent who left, it first checks whether another agent is still on the call, for
# the case where that check itself failed in the webhook.
class Voice::EndConferenceJob < ApplicationJob
  queue_as :critical

  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(call_id, leaving_label: nil)
    call = Call.find_by(id: call_id)
    return if call.blank? || !call.twilio?

    conference = Voice::Provider::Twilio::ConferenceService.new(call: call)
    return if leaving_label && conference.agents_remain?(leaving_label: leaving_label)

    conference.end_conference
    complete(call) if leaving_label
  end

  private

  def complete(call)
    return if call.terminal?

    Voice::CallStatus::Manager.new(call: call).process_status_update('completed', timestamp: Time.zone.now.to_i)
  end
end
