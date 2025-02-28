class Inboxes::FetchImapEmailInboxesJob < ApplicationJob
  queue_as :one_min_mailer

  def perform
    Inbox.where(channel_type: 'Channel::Email').all.find_each(batch_size: 100) do |inbox|
      ::Inboxes::FetchImapEmailsJob.perform_later(inbox.channel) if inbox.channel.imap_enabled
    end
  end
end
