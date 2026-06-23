class Whatsapp::SetupWebhooksJob < ApplicationJob
  queue_as :medium

  # Runs the post-creation webhook setup and health check outside the web request.
  # These hit the Meta Graph API and can be slow enough to exceed the request timeout,
  # so the embedded signup controller returns as soon as the channel is persisted and
  # this job finishes the setup asynchronously.
  def perform(channel, run_health_check: true)
    channel.setup_webhooks
    check_channel_health_and_prompt_reauth(channel) if run_health_check
  end

  private

  def check_channel_health_and_prompt_reauth(channel)
    health_data = Whatsapp::HealthService.new(channel).fetch_health_status
    return unless health_data

    if channel_in_pending_state?(health_data)
      channel.prompt_reauthorization!
    else
      Rails.logger.info "[WHATSAPP] Channel #{channel.phone_number} health check passed"
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Health check failed for channel #{channel.phone_number}: #{e.message}"
  end

  def channel_in_pending_state?(health_data)
    health_data[:platform_type] == 'NOT_APPLICABLE' ||
      health_data.dig(:throughput, 'level') == 'NOT_APPLICABLE'
  end
end
