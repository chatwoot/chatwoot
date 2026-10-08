# Applies Twilio's current status to an outbound call once its row is visible. The call
# is dialled before its row commits, so a status callback can arrive while there is no
# call to apply it to; reading the status afterwards recovers what that callback carried.
class Voice::SyncProviderStatusJob < ApplicationJob
  queue_as :high

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return if call.blank? || !call.twilio? || call.terminal?

    twilio_call = call.inbox.channel.client.calls(call.provider_call_id).fetch
    Voice::StatusUpdateService.new(
      account: call.account, call_sid: call.provider_call_id, call_status: twilio_call.status, payload: timing(twilio_call)
    ).perform
  end

  private

  # The times a callback would have carried: when the call was answered while it is live,
  # when it ended once over, and how long it lasted
  def timing(twilio_call)
    moment = twilio_call.end_time || twilio_call.start_time
    { 'Timestamp' => moment&.iso8601, 'CallDuration' => twilio_call.duration }.compact
  end
end
