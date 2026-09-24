class Inboxes::FetchGooglePlayReviewsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(channel)
    channel.with_lock do
      next unless channel.sync_due?

      channel.fetch_reviews.each do |review|
        ::GooglePlay::ReviewBuilder.new(review: review, channel: channel).perform
      rescue StandardError => e
        ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
      end

      channel.update!(last_synced_at: Time.current)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end
end
