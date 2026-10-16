# Hangs up a contact's call leg that a direct attempt could not, as when a failed agent join
# ends a call whose conference never started, so the contact is not left waiting until
# Twilio's own timeout
class Voice::HangUpContactJob < ApplicationJob
  queue_as :critical
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return if call.blank? || !call.twilio?

    Voice::Provider::Twilio::ConferenceService.new(call: call).terminate_call
  end
end
