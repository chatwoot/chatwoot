# Moves every Z-API inbox from the old webhook URL, which carried only the phone number, to the
# one that carries a token. Until the new URL is confirmed the old one keeps taking the inbox's
# events, so an inbox this job cannot reach (Z-API down, credentials revoked) keeps working the
# way it did and is listed in the log. So is an instance whose webhooks do not all point at the
# old URL: re-registering overwrites every one of them, and the job does not take over an event
# someone sent elsewhere. Setting the inbox up again from its settings page moves either kind.
#
# Run again by hand: Migration::ZapiWebhookUrlJob.perform_now
class Migration::ZapiWebhookUrlJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    stats = { moved: 0, skipped: 0, failed: 0 }

    Channel::Whatsapp.where(provider: 'zapi').find_each do |channel|
      service = Whatsapp::Providers::WhatsappZapiService.new(whatsapp_channel: channel)
      next if service.webhook_url_confirmed?

      checked = channel.provider_config.slice('instance_id', 'token')
      unless service.webhooks_on_legacy_url?
        stats[:skipped] += 1
        next Rails.logger.warn("[zapi-webhook-url] left alone, webhooks point elsewhere channel_id=#{channel.id}")
      end

      service.register_webhooks(expected_instance: checked)
      stats[:moved] += 1
    rescue StandardError => e
      stats[:failed] += 1
      Rails.logger.warn("[zapi-webhook-url] still on the old URL channel_id=#{channel.id} error=#{e.class}: #{e.message}")
    end

    Rails.logger.info("[zapi-webhook-url] completed #{stats.inspect}")
    stats
  end
end
