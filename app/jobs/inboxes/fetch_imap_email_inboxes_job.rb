class Inboxes::FetchImapEmailInboxesJob < ApplicationJob
  queue_as :scheduled_jobs
  include BillingHelper

  def perform
    email_inboxes = Inbox.where(channel_type: 'Channel::Email')
    email_inboxes.find_each(batch_size: 100) do |inbox|
      next unless should_fetch_emails?(inbox)

      Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Enqueuing fetch job for inbox #{inbox.id}"
      ::Inboxes::FetchImapEmailsJob.perform_later(inbox.channel)
    end
  end

  private

  def should_fetch_emails?(inbox)
    return false if inbox.account.suspended?
    return false unless inbox.channel.imap_enabled
    return false if inbox.channel.reauthorization_required?

    return true unless ChatwootApp.chatwoot_cloud?
    return false if default_plan?(inbox.account)

    true
  end
end
