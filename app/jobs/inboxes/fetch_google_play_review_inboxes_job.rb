class Inboxes::FetchGooglePlayReviewInboxesJob < ApplicationJob
  queue_as :scheduled_jobs

  # Runs every 15 minutes via cron. Each inbox syncs at most once per Channel::GooglePlay::SYNC_INTERVAL
  # (one hour) — the extra cron ticks act as quick retries when a sync window is missed.
  def perform
    Inbox.where(channel_type: 'Channel::GooglePlay').find_each(batch_size: 100) do |inbox|
      next if inbox.account.suspended?
      next unless inbox.channel.sync_due?

      ::Inboxes::FetchGooglePlayReviewsJob.perform_later(inbox.channel)
    end
  end
end
