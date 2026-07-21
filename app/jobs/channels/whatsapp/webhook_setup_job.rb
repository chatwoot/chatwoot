class Channels::Whatsapp::WebhookSetupJob < ApplicationJob
  queue_as :low

  # Runs Meta's phone-registration and webhook-subscription calls off the request
  # thread. Inline, these Graph API calls can exceed the 15s Rack::Timeout and, since
  # RequestTimeoutException bypasses setup_webhooks' rescue, abort inbox creation and
  # roll it back — leaving the number connected on Meta but no inbox in Chatwoot.
  def perform(whatsapp_channel)
    whatsapp_channel.setup_webhooks
  end
end
