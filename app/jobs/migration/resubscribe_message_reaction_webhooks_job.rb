class Migration::ResubscribeMessageReactionWebhooksJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    resubscribe_facebook_pages
    resubscribe_instagram_channels
    resubscribe_telegram_channels
    resubscribe_whatsapp_channels
  end

  private

  def resubscribe_facebook_pages
    Channel::FacebookPage.find_each { |channel| safely(channel) { channel.subscribe } }
  end

  def resubscribe_instagram_channels
    Channel::Instagram.find_each { |channel| safely(channel) { channel.subscribe } }
  end

  def resubscribe_telegram_channels
    Channel::Telegram.find_each do |channel|
      safely(channel) do
        channel.setup_telegram_webhook
        raise StandardError, channel.errors.full_messages.to_sentence if channel.errors.present?
      end
    end
  end

  # 360dialog channels don't use Whatsapp::WebhookSetupService, so only whatsapp_cloud
  # channels are relevant here. Calling setup_webhooks is idempotent, so re-running it
  # for existing channels (including embedded-signup ones) is safe.
  def resubscribe_whatsapp_channels
    Channel::Whatsapp.where(provider: 'whatsapp_cloud').find_each { |channel| safely(channel) { channel.setup_webhooks } }
  end

  def safely(channel)
    yield
  rescue StandardError => e
    Rails.logger.error("[MessageReactions] Failed to resubscribe channel #{channel.class.name}##{channel.id}: #{e.message}")
  end
end
