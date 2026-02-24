require 'net/imap'

class Inboxes::FetchImapEmailsJob < MutexApplicationJob
  queue_as :scheduled_jobs

  def perform(channel, interval = 1)
    return unless should_fetch_email?(channel)

    fetch_emails_with_backoff(channel, interval)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end

  private

  def fetch_emails_with_backoff(channel, interval)
    key = format(::Redis::Alfred::EMAIL_MESSAGE_MUTEX, inbox_id: channel.inbox.id)
    with_lock(key, 5.minutes) { process_email_for_channel(channel, interval) }
    channel.clear_backoff!
  rescue Imap::AuthenticationError => e
    Rails.logger.error "#{channel.backoff_log_identifier} authentication error : #{e.message}"
    channel.authorization_error!
  rescue *ExceptionList::IMAP_TRANSIENT_EXCEPTIONS => e
    Rails.logger.error "#{channel.backoff_log_identifier} transient error : #{e.message}"
    channel.apply_backoff!
  rescue LockAcquisitionError
    Rails.logger.error "Lock failed for #{channel.inbox.id}"
  end

  def should_fetch_email?(channel)
    channel.imap_enabled? && !channel.reauthorization_required? && !channel.in_backoff?
  end

  def process_email_for_channel(channel, interval)
    inbound_emails = if channel.microsoft?
                       Imap::MicrosoftFetchEmailService.new(channel: channel, interval: interval).perform
                     elsif channel.google?
                       Imap::GoogleFetchEmailService.new(channel: channel, interval: interval).perform
                     else
                       Imap::FetchEmailService.new(channel: channel, interval: interval).perform
                     end
    inbound_emails.map do |inbound_mail|
      process_mail(inbound_mail, channel)
    end
  rescue OAuth2::Error => e
    Rails.logger.error "Error for email channel - #{channel.inbox.id} : #{e.message}"
    channel.authorization_error!
  end

  def process_mail(inbound_mail, channel)
    Imap::ImapMailbox.new.process(inbound_mail, channel)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
    Rails.logger.error("
      #{channel.provider} Email dropped: #{inbound_mail.from} and message_source_id: #{inbound_mail.message_id}")
  end
end
