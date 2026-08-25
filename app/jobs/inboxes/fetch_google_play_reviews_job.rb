class Inboxes::FetchGooglePlayReviewsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(channel)
    channel.fetch_reviews.each do |review|
      ::GooglePlay::ReviewBuilder.new(review: review, channel: channel).perform
    rescue StandardError => e
      ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
    end

    # Stamp the channel so the orchestrator skips it until the sync interval elapses.
    channel.update!(last_synced_at: Time.current)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end
end
