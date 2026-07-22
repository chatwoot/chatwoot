class Channels::Whatsapp::WebhookSetupJob < ApplicationJob
  queue_as :low

  # Runs Meta's phone-registration and webhook-subscription calls off the request
  # thread. Inline, these Graph API calls can exceed the 15s Rack::Timeout and, since
  # RequestTimeoutException bypasses setup_webhooks' rescue, abort inbox creation and
  # roll it back — leaving the number connected on Meta but no inbox in Chatwoot.
  def perform(whatsapp_channel, run_health_check: false)
    whatsapp_channel.setup_webhooks
    # Health check runs only after registration so a freshly provisioned number
    # isn't flagged as pending before setup_webhooks has a chance to register it.
    whatsapp_channel.check_provisioning_health if run_health_check
  end
end
