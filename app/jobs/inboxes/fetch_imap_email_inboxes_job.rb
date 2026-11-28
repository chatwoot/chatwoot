class Inboxes::FetchImapEmailInboxesJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    email_inboxes = Inbox.where(channel_type: 'Channel::Email')
    email_inboxes.find_each(batch_size: 100) do |inbox|
      next unless inbox.channel.imap_fetchable?

      Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Enqueuing fetch job for inbox #{inbox.id}"
      ::Inboxes::FetchImapEmailsJob.perform_later(inbox.channel)
    end
  end
end
