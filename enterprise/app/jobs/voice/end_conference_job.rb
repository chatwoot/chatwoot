# Ends a call's Twilio conference when the request failed at the moment the last agent
# left, so the contact is not left alone until Twilio's own timeout. Given the call SID
# of the leg that left, it first checks whether another agent is still on the call, for
# the case where that check itself failed in the webhook.
class Voice::EndConferenceJob < ApplicationJob
  queue_as :critical

  # Rounds of the job queued again after a round's retries were all refused
  LATE_ROUNDS = 3
  LATE_ROUND_WAIT = 5.minutes

  # Once the retries are spent the call is not left live: a last attempt ends the
  # conference and the call completes either way. A conference Twilio would still not
  # end is tried again in a later round, so the contact is not left in it.
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

  # A last attempt that still checks for an agent left on the call first, so a conference
  # someone is still on is never ended; one Twilio will not answer is tried again in a later
  # round, and the call completes once the rounds run out
  def give_up(call, round, leaving_call_sid)
    conference = Voice::Provider::Twilio::ConferenceService.new(call: call)
    return if leaving_call_sid && agent_still_on_call?(conference, call, leaving_call_sid)

    hung_up = hang_up_dialled_contact(call)
    conference.end_conference
    complete(call)
  rescue StandardError => e
    Rails.logger.error("[VOICE] call #{call.id}: last attempt to end the conference failed: #{e.class}: #{e.message}")
    return self.class.set(wait: LATE_ROUND_WAIT).perform_later(call.id, leaving_call_sid: leaving_call_sid, round: round + 1) if round < LATE_ROUNDS

    # The rounds are spent, even if who is on the call could not be checked
    hang_up_dialled_contact(call) unless hung_up
    complete(call)
  end

  # Another agent is in the conference or on their way in, in which case the check runs again
  # once their time to join is up; with none, the call is completed first, under the row
  # lock opening a connection takes, so one opened later finds the call over
  def agent_still_on_call?(conference, call, leaving_call_sid)
    looked_at = Time.zone.now.to_i
    return true if conference.agents_remain?(leaving_call_sid: leaving_call_sid)

    wait = conference.complete_unless_agent_joining(leaving_call_sid: leaving_call_sid, since: looked_at)
    self.class.set(wait: wait.seconds).perform_later(call.id, leaving_call_sid: leaving_call_sid) if wait&.positive?
    wait.present?
  end

  # An outbound contact still being dialled is not in the conference yet, so ending it does
  # not reach them; their leg is hung up by a job that retries if Twilio fails
  def hang_up_dialled_contact(call)
    Voice::HangUpContactJob.perform_later(call.id) if call.outgoing?
    true
  end

  def complete(call)
    return if call.terminal?

    Voice::CallStatus::Manager.new(call: call).process_status_update('completed', timestamp: Time.zone.now.to_i)
  end
end
