require 'net/imap'

class Inboxes::FetchImapEmailsJob < MutexApplicationJob
  queue_as :scheduled_jobs

  def perform(channel, interval = 1)
    return unless should_fetch_email?(channel)

    key = format(::Redis::Alfred::EMAIL_MESSAGE_MUTEX, inbox_id: channel.inbox.id)

    with_lock(key, 5.minutes) do
      process_email_for_channel(channel, interval)
    end
  rescue *ExceptionList::IMAP_EXCEPTIONS => e
    Rails.logger.error "Authorization error for email channel - #{channel.inbox.id} : #{e.message}"
  rescue EOFError, OpenSSL::SSL::SSLError, Net::IMAP::NoResponseError, Net::IMAP::BadResponseError, Net::IMAP::InvalidResponseError => e
    Rails.logger.error "Error for email channel - #{channel.inbox.id} : #{e.message}"
  rescue LockAcquisitionError
    Rails.logger.error "Lock failed for #{channel.inbox.id}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end

  private

  def should_fetch_email?(channel)
    channel.imap_enabled? && !channel.reauthorization_required?
  end

  def process_email_for_channel(channel, interval)
    inbound_emails = if channel.microsoft?
                       Imap::MicrosoftFetchEmailService.new(channel: channel, interval: interval).perform
                     elsif channel.google?
                       Imap::GoogleFetchEmailService.new(channel: channel, interval: interval).perform
                     else
                       Imap::FetchEmailService.new(channel: channel, interval: interval).perform
                     end

    inbound_emails.each do |inbound_mail|
      process_mail(inbound_mail, channel)
    end
  rescue OAuth2::Error => e
    Rails.logger.error "Error for email channel - #{channel.inbox.id} : #{e.message}"
    channel.authorization_error!
  end

  def should_skip_email?(message_id)
    failure_count = Rails.cache.read("email_failures:#{message_id}") || 0
    failure_count >= 3
  end

  def mark_email_as_failed(message_id)
    failure_count = Rails.cache.read("email_failures:#{message_id}") || 0
    Rails.cache.write("email_failures:#{message_id}", failure_count + 1, expires_in: 6.hours)
  end

  def process_mail(inbound_mail, channel)
    # Skip if this email has failed multiple times recently
    if should_skip_email?(inbound_mail.message_id)
      Rails.logger.warn "[IMAP] Skipping problematic email: #{inbound_mail.message_id}"
      return
    end

    begin
      Timeout.timeout(email_processing_timeout) do
        Imap::ImapMailbox.new.process(inbound_mail, channel)
      end
    rescue Timeout::Error
      mark_email_as_failed(inbound_mail.message_id)
      Rails.logger.error "[IMAP] Email processing timeout (#{email_processing_timeout}s): #{inbound_mail.message_id}"
    rescue StandardError => e
      mark_email_as_failed(inbound_mail.message_id)
      Rails.logger.error "[IMAP] Failed to process email #{inbound_mail.message_id}: #{e.message}"
      ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
    end
  end

  def email_processing_timeout
    GlobalConfigService.load('EMAIL_PROCESSING_TIMEOUT', 15).to_i
  end
end
