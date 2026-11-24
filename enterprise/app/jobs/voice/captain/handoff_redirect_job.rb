# Moves a caller off Captain's Vapi call and back to our call webhook, which rings agents as for any inbound call
class Voice::Captain::HandoffRedirectJob < ApplicationJob
  queue_as :high

  def perform(inbox_id, twilio_call_sid)
    channel = Inbox.find(inbox_id).channel
    channel.client.calls(twilio_call_sid).update(url: channel.voice_call_webhook_url, method: 'POST')
  end
end
