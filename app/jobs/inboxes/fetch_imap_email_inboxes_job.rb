class Inboxes::FetchImapEmailInboxesJob < ApplicationJob
  queue_as :low

  def perform
    Inbox.where(channel_type: 'Channel::Email').all.each do |inbox|
      next unless inbox.channel.imap_enabled

      if ENV.fetch('AZURE_TENANT_ID', false) && inbox.channel.microsoft?
        ::Inboxes::FetchMsGraphEmailsJob.perform_later(inbox.channel)
      else
        ::Inboxes::FetchImapEmailsJob.perform_later(inbox.channel)
      end
    end
  end
end
