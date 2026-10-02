class Inboxes::FetchAppStoreReviewInboxesJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Inbox.includes(:account, :channel).where(channel_type: 'Channel::AppStore').find_each(batch_size: 100) do |inbox|
      account = inbox.account
      channel = inbox.channel

      next if account.suspended?
      next unless account.feature_enabled?(:channel_app_store)
      next unless channel.sync_due?

      ::Inboxes::FetchAppStoreReviewsJob.perform_later(channel)
    end
  end
end
