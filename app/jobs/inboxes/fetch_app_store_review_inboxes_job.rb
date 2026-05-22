class Inboxes::FetchAppStoreReviewInboxesJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    return unless app_store_reviews_enabled?

    Inbox.where(channel_type: 'Channel::AppStore').find_each(batch_size: 100) do |inbox|
      next if inbox.account.suspended?
      next unless inbox.channel.sync_due?

      ::Inboxes::FetchAppStoreReviewsJob.perform_later(inbox.channel)
    end
  end

  private

  def app_store_reviews_enabled?
    GlobalConfigService.load('ENABLE_APP_STORE_REVIEWS_CHANNEL', 'false').to_s == 'true'
  end
end
