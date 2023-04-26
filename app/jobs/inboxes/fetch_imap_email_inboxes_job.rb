class Inboxes::FetchImapEmailInboxesJob < ApplicationJob
  queue_as :low

  def perform
    Inbox.where(channel_type: 'Channel::Email', imap_enabled: true).all.find_each(batch_size: 100) do |inbox|
      if inbox.channel.microsoft? && ENV.fetch('AZURE_TENANT_ID', false)
        ::Inboxes::FetchMsGraphEmailsJob.perform_later(inbox.channel)
      else
        ::Inboxes::FetchImapEmailsJob.perform_later(inbox.channel)
      end
    end
  end
end
