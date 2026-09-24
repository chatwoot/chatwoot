class Inboxes::FetchAppStoreReviewsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(channel)
    return unless channel.account.feature_enabled?(:channel_app_store)

    with_sync_lock(channel) do
      next unless channel.reload.sync_due?
      next unless sync_reviews(channel)

      channel.update!(last_synced_at: Time.current)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end

  private

  def with_sync_lock(channel)
    ApplicationRecord.connection_pool.with_connection do |connection|
      lock_key = connection.quote("app_store_reviews:#{channel.id}")
      lock_id = "hashtextextended(#{lock_key}, 0)"
      next unless connection.uncached { connection.select_value("SELECT pg_try_advisory_lock(#{lock_id})") }

      begin
        yield
      ensure
        connection.execute("SELECT pg_advisory_unlock(#{lock_id})")
      end
    end
  end

  def sync_reviews(channel)
    failed = false
    sync_started_at = Time.current

    channel.fetch_reviews.each do |review_payload|
      ::AppStore::ReviewBuilder.new(review_payload: review_payload, channel: channel, sync_started_at: sync_started_at).perform
    rescue StandardError => e
      failed = true
      ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
    end

    !failed
  end
end
