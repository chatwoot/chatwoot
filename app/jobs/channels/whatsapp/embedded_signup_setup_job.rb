# Finishes an Embedded Signup after the inbox exists: registers the number, subscribes webhooks and checks health.
# These Meta calls take several seconds (/register alone can take most of them), so running them inside the
# authorization request could push it past the request timeout and leave a half-set-up inbox.
# Failures here prompt reauthorization on the inbox, which shows the reconnect banner and emails the admins.
class Channels::Whatsapp::EmbeddedSignupSetupJob < ApplicationJob
  queue_as :high

  def perform(channel, is_coexistence:, check_health:)
    return unless set_up_number(channel, is_coexistence)

    check_health_and_prompt_reauth(channel) if check_health
  end

  private

  # WebhookSetupService keeps going after a failed /register so the webhook still gets subscribed, and only
  # records the error. An unregistered number receives nothing, so treat that as a failed setup too.
  def set_up_number(channel, is_coexistence)
    webhook_setup = Whatsapp::WebhookSetupService.new(channel, is_coexistence: is_coexistence)
    webhook_setup.perform
    raise webhook_setup.registration_error if webhook_setup.registration_error

    true
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Embedded signup setup failed for channel #{channel.id}: #{e.message}"
    channel.prompt_reauthorization!
    false
  end

  def check_health_and_prompt_reauth(channel)
    health_data = Whatsapp::HealthService.new(channel).fetch_health_status
    return unless health_data

    if pending_provisioning?(health_data)
      channel.prompt_reauthorization!
    else
      Rails.logger.info "[WHATSAPP] Channel #{channel.phone_number} health check passed"
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Health check failed for channel #{channel.phone_number}: #{e.message}"
  end

  def pending_provisioning?(health_data)
    health_data[:platform_type] == 'NOT_APPLICABLE' ||
      health_data.dig(:throughput, 'level') == 'NOT_APPLICABLE'
  end
end
