class Channels::Whatsapp::WebhookSetupJob < ApplicationJob
  queue_as :low

  # Meta's Graph API calls (phone registration + webhook subscription) are slow and fail
  # transiently. Retry a few times, and once retries are exhausted mark the channel for
  # reauthorization so the inbox has a visible recovery path instead of silently missing its
  # webhook subscription. Running these off the request thread also keeps them clear of the
  # 15s Rack::Timeout, which previously aborted inbox creation and rolled it back.
  retry_on StandardError, wait: :polynomially_longer, attempts: 3 do |job, error|
    channel = job.arguments.first
    Rails.logger.error("[WHATSAPP] Webhook setup failed after retries: #{error.message}")
    channel.prompt_reauthorization! if channel.is_a?(Channel::Whatsapp)
  end

  # A deleted channel can't be set up; discard instead of retrying (takes precedence over
  # the StandardError retry above, which would otherwise catch DeserializationError too).
  discard_on ActiveJob::DeserializationError

  def perform(whatsapp_channel, run_health_check: false)
    whatsapp_channel.setup_webhooks
    # Health check runs only after registration so a freshly provisioned number
    # isn't flagged as pending before setup_webhooks has a chance to register it.
    whatsapp_channel.check_provisioning_health if run_health_check
  end
end
