class Inboxes::FetchImapEmailInboxesJob < ApplicationJob
  queue_as :one_min_mailer

  def perform
    email_inboxes = Inbox.where(channel_type: 'Channel::Email')
    email_inboxes.find_each(batch_size: 100) do |inbox|
      ::Inboxes::FetchImapEmailsJob.perform_later(inbox.channel) if should_fetch_emails?(inbox)
    end
  end

  private

  def should_fetch_emails?(inbox)
    inbox.channel.imap_enabled && !inbox.account.suspended?
  end
end
