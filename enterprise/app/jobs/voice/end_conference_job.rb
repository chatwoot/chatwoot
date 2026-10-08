# Ends a call's Twilio conference when the request failed at the moment the last agent
# left, so the contact is not left alone until Twilio's own timeout. Given the call SID
# of the leg that left, it first checks whether another agent is still on the call, for
# the case where that check itself failed in the webhook.
class Voice::EndConferenceJob < ApplicationJob
  queue_as :critical

  # Once the retries are spent the call is not left live: a last attempt ends the
  # conference and the call completes either way
  retry_on StandardError, wait: :polynomially_longer, attempts: 5 do |job, error|
    call = Call.find_by(id: job.arguments.first)
    if call&.twilio?
      Rails.logger.error("[VOICE] call #{call.id}: ending the conference after retries failed: #{error.class}: #{error.message}")
      job.send(:give_up, call)
    end
  end

  def perform(call_id, leaving_call_sid: nil)
    call = Call.find_by(id: call_id)
    return if call.blank? || !call.twilio?

    conference = Voice::Provider::Twilio::ConferenceService.new(call: call)
    return if leaving_call_sid && conference.agents_remain?(leaving_call_sid: leaving_call_sid)

    conference.end_conference
    complete(call) if leaving_call_sid
  end

  private

  def give_up(call)
    begin
      Voice::Provider::Twilio::ConferenceService.new(call: call).end_conference
    rescue StandardError => e
      Rails.logger.error("[VOICE] call #{call.id}: last attempt to end the conference failed: #{e.class}: #{e.message}")
    end
    complete(call)
  end

  def complete(call)
    return if call.terminal?

    Voice::CallStatus::Manager.new(call: call).process_status_update('completed', timestamp: Time.zone.now.to_i)
  end
end
