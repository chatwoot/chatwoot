class Migration::ResubscribeMessageReactionWebhooksJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    stats = { checked: 0, succeeded: 0, failed: 0, skipped: 0 }

    resubscribe_facebook_pages(stats)
    resubscribe_instagram_channels(stats)
    resubscribe_telegram_channels(stats)
    resubscribe_whatsapp_channels(stats)

    Rails.logger.info("[MessageReactions] Resubscribe complete: #{stats.inspect}")
    stats
  end

  private

  def resubscribe_facebook_pages(stats)
    Channel::FacebookPage.find_each { |channel| safely(channel, stats) { channel.subscribe } }
  end

  def resubscribe_instagram_channels(stats)
    Channel::Instagram.find_each { |channel| safely(channel, stats) { channel.subscribe } }
  end

  def resubscribe_telegram_channels(stats)
    Channel::Telegram.find_each do |channel|
      safely(channel, stats) do
        channel.setup_telegram_webhook
        raise StandardError, channel.errors.full_messages.to_sentence if channel.errors.present?
      end
    end
  end

  # 360dialog channels (provider != 'whatsapp_cloud') don't use Whatsapp::WebhookSetupService,
  # so they're counted as skipped rather than being processed.
  def resubscribe_whatsapp_channels(stats)
    Channel::Whatsapp.find_each do |channel|
      if channel.provider == 'whatsapp_cloud'
        safely(channel, stats) { channel.setup_webhooks }
      else
        stats[:checked] += 1
        stats[:skipped] += 1
      end
    end
  end

  # NOTE: Channel::FacebookPage#subscribe, Channel::Instagram#subscribe, and
  # Channel::Whatsapp#setup_webhooks all rescue StandardError internally and always return
  # truthy, so "succeeded" here only means "no exception surfaced to this method" — it does
  # not mean the provider confirmed the subscription actually took effect.
  def safely(channel, stats)
    stats[:checked] += 1
    yield
    stats[:succeeded] += 1
  rescue StandardError => e
    stats[:failed] += 1
    Rails.logger.error("[MessageReactions] Failed to resubscribe channel #{channel.class.name}##{channel.id}: #{e.message}")
  end
end
