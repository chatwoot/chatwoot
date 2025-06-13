class Webhooks::FacebookFeedEventsJob < MutexApplicationJob
  queue_as :default
  retry_on LockAcquisitionError, wait: 1.second, attempts: 8

  def perform(feed_message)
    response = ::Integrations::Facebook::FeedMessageParser.new(feed_message)

    key = format(::Redis::Alfred::FACEBOOK_FEED_MESSAGE_MUTEX, sender_id: response.sender_id, post_id: response.post_id)
    with_lock(key) do
      process_feed_message(response)
    end
  end

  def process_feed_message(response)
    ::Integrations::Facebook::FeedMessageCreator.new(response).perform
  end
end
