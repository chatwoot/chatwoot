class Inboxes::FetchAppStoreReviewsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(channel)
    return unless channel.account.feature_enabled?(:channel_app_store)

    synced_until = sync_reviews(channel)
    return if synced_until.blank?

    channel.update!(last_synced_at: synced_until)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end

  private

  def sync_reviews(channel)
    failed = false
    synced_dates = []

    channel.fetch_reviews.each do |review_payload|
      ::AppStore::ReviewBuilder.new(review_payload: review_payload, channel: channel).perform
      synced_dates << payload_synced_at(review_payload)
    rescue StandardError => e
      failed = true
      ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
    end

    return if failed

    [channel.last_synced_at, synced_dates.compact.max].compact.max
  end

  def payload_synced_at(review_payload)
    [
      parsed_timestamp(review_payload.dig('review', 'attributes', 'createdDate')),
      parsed_timestamp(review_payload.dig('response', 'attributes', 'lastModifiedDate'))
    ].compact.max
  end

  def parsed_timestamp(value)
    Time.zone.parse(value.to_s)
  rescue StandardError
    nil
  end
end
