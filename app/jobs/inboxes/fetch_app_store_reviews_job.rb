class Inboxes::FetchAppStoreReviewsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(channel)
    return unless app_store_reviews_enabled?

    channel.fetch_reviews.each do |review_payload|
      ::AppStore::ReviewBuilder.new(review_payload: review_payload, channel: channel).perform
    rescue StandardError => e
      ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
    end

    channel.update!(last_synced_at: Time.current)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end

  private

  def app_store_reviews_enabled?
    GlobalConfigService.load('ENABLE_APP_STORE_REVIEWS_CHANNEL', 'false').to_s == 'true'
  end
end
