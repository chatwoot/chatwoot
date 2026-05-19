class Inboxes::FetchGooglePlayReviewsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(channel)
    channel.fetch_reviews.each do |review|
      ::GooglePlay::ReviewBuilder.new(review: review, channel: channel).perform
    rescue StandardError => e
      ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end
end
