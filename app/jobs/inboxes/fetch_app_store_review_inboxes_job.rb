class Inboxes::FetchAppStoreReviewInboxesJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Inbox.where(channel_type: 'Channel::AppStore').find_each(batch_size: 100) do |inbox|
      next if inbox.account.suspended?
      next unless inbox.account.feature_enabled?(:channel_app_store)
      next unless inbox.channel.sync_due?

      ::Inboxes::FetchAppStoreReviewsJob.perform_later(inbox.channel)
    end
  end
end
