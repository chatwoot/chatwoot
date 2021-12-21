class Inboxes::FetchImapEmailInboxesJob < ApplicationJob
  queue_as :low

  def perform
    Inbox.where(channel_type: 'Channel::Email').all.each do |inbox|
      ::Inboxes::FetchImapEmailsJob.perform_later(inbox.channel) if inbox.channel.imap_enabled
    end
  end
end
