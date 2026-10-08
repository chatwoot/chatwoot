# Applies Twilio's current status to an outbound call once its row is visible. The call
# is dialled before its row commits, so a status callback can arrive while there is no
# call to apply it to; reading the status afterwards recovers what that callback carried.
class Voice::SyncProviderStatusJob < ApplicationJob
  queue_as :high

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return if call.blank? || !call.twilio? || call.terminal?

    status = call.inbox.channel.client.calls(call.provider_call_id).fetch.status
    Voice::StatusUpdateService.new(account: call.account, call_sid: call.provider_call_id, call_status: status).perform
  end
end
