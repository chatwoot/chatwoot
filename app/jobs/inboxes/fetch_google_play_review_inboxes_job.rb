class Inboxes::FetchGooglePlayReviewInboxesJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Inbox.where(channel_type: 'Channel::GooglePlay').find_each(batch_size: 100) do |inbox|
      next if inbox.account.suspended?

      ::Inboxes::FetchGooglePlayReviewsJob.perform_later(inbox.channel)
    end
  end
end
