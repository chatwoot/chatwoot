class Voice::HangUpContactJob < ApplicationJob
  queue_as :critical
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return if call.blank? || !call.twilio?

    Voice::Provider::Twilio::ConferenceService.new(call: call).terminate_call
  end
end
