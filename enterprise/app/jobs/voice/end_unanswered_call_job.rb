# Ends a Twilio call nobody answered within the inbox's ring time; queued as the ring starts
class Voice::EndUnansweredCallJob < ApplicationJob
  queue_as :critical
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return if call.blank?

    wait = Voice::RingingTimeoutService.new(call: call).perform
    self.class.set(wait: wait.seconds).perform_later(call.id) if wait
  end
end
