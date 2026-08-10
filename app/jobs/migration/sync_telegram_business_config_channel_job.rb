class Migration::SyncTelegramBusinessConfigChannelJob < ApplicationJob
  class RefreshFailed < StandardError; end

  queue_as :async_database_migration

  def perform(channel_id)
    channel = Channel::Telegram.find_by(id: channel_id)
    return unless channel
    return if channel.refresh_business_config!

    raise RefreshFailed, "Telegram Business config refresh failed for channel ID: #{channel_id}"
  end
end
