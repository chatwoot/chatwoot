class Inboxes::FetchAppStoreReviewsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(channel)
    channel.fetch_reviews.each do |review_payload|
      ::AppStore::ReviewBuilder.new(review_payload: review_payload, channel: channel).perform
    rescue StandardError => e
      ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
    end

    channel.update!(last_synced_at: Time.current)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end
end
