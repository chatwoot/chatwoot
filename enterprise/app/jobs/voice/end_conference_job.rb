class Voice::EndConferenceJob < ApplicationJob
  queue_as :critical

  LATE_ROUNDS = 3
  LATE_ROUND_WAIT = 5.minutes

  retry_on StandardError, wait: :polynomially_longer, attempts: 5 do |job, error|
    call = Call.find_by(id: job.arguments.first)
    if call&.twilio?
      Rails.logger.error("[VOICE] call #{call.id}: ending the conference after retries failed: #{error.class}: #{error.message}")
      options = job.arguments.last.is_a?(Hash) ? job.arguments.last : {}
      job.send(:give_up, call, options[:round].to_i, options[:leaving_call_sid])
    end
  end

  def perform(call_id, leaving_call_sid: nil, round: 0) # rubocop:disable Lint/UnusedMethodArgument
    call = Call.find_by(id: call_id)
    return if call.blank? || !call.twilio?

    conference = Voice::Provider::Twilio::ConferenceService.new(call: call)
    return if leaving_call_sid && agent_still_on_call?(conference, call, leaving_call_sid)

    conference.end_conference
    hang_up_dialled_contact(call)
  end

  private

  def give_up(call, round, leaving_call_sid)
    conference = Voice::Provider::Twilio::ConferenceService.new(call: call)
    return if leaving_call_sid && agent_still_on_call?(conference, call, leaving_call_sid)

    hung_up = hang_up_dialled_contact(call)
    conference.end_conference
    complete(call)
  rescue StandardError => e
    Rails.logger.error("[VOICE] call #{call.id}: last attempt to end the conference failed: #{e.class}: #{e.message}")
    return self.class.set(wait: LATE_ROUND_WAIT).perform_later(call.id, leaving_call_sid: leaving_call_sid, round: round + 1) if round < LATE_ROUNDS

    # Exhausted retries complete the call even if the participant lookup still fails.
    hang_up_dialled_contact(call) unless hung_up
    complete(call)
  end

  def agent_still_on_call?(conference, call, leaving_call_sid)
    looked_at = Time.zone.now.to_i
    return true if conference.agents_remain?(leaving_call_sid: leaving_call_sid)

    wait = conference.complete_unless_agent_joining(leaving_call_sid: leaving_call_sid, since: looked_at)
    self.class.set(wait: wait.seconds).perform_later(call.id, leaving_call_sid: leaving_call_sid) if wait&.positive?
    wait.present?
  end

  # An outbound contact may still be ringing outside the conference.
  def hang_up_dialled_contact(call)
    Voice::HangUpContactJob.perform_later(call.id) if call.outgoing?
    true
  end

  def complete(call)
    return if call.terminal?

    Voice::CallStatus::Manager.new(call: call).process_status_update('completed', timestamp: Time.zone.now.to_i)
  end
end
