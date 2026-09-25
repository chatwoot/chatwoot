# Ends a call's Twilio conference when the request failed at the moment the last agent
# left, so the contact is not left alone until Twilio's own timeout
class Voice::EndConferenceJob < ApplicationJob
  queue_as :critical

  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return if call.blank? || !call.twilio?

    Voice::Provider::Twilio::ConferenceService.new(call: call).end_conference
  end
end
