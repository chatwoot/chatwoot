class Inboxes::FetchImapEmailInboxesJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    # check imap_enabled for channel
    Inbox.where(channel_type: 'Channel::Email').all.find_each(batch_size: 100) do |inbox|
      next unless inbox.channel.imap_enabled?

      fetch_emails(inbox)
    end
  end

  def fetch_emails(inbox)
    if inbox.channel.microsoft? && ENV.fetch('AZURE_TENANT_ID', false)
      ::Inboxes::FetchMsGraphEmailsJob.perform_later(inbox.channel)
    else
      ::Inboxes::FetchImapEmailsJob.perform_later(inbox.channel)
    end
  end
end
