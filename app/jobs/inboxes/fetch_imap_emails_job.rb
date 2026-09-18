require 'net/imap'

class Inboxes::FetchImapEmailsJob < MutexApplicationJob
  queue_as :scheduled_jobs

  def perform(channel, interval = 1)
    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Job started for inbox #{channel.inbox.id}"

    return log_skipped_fetch(channel) unless should_fetch_email?(channel)

    fetch_mails_with_lock(channel, interval)
  rescue *ExceptionList::IMAP_EXCEPTIONS => e
    Rails.logger.error "Authorization error for email channel - #{channel.inbox.id} : #{e.message}"
  rescue IOError, OpenSSL::SSL::SSLError, Net::IMAP::NoResponseError, Net::IMAP::BadResponseError, Net::IMAP::InvalidResponseError,
         Net::IMAP::ResponseParseError, Net::IMAP::ResponseReadError, Net::IMAP::ResponseTooLargeError => e
    Rails.logger.error "Error for email channel - #{channel.inbox.id} : #{e.message}"
  rescue LockAcquisitionError
    Rails.logger.error "Lock failed for #{channel.inbox.id}"
  rescue StandardError => e
    handle_unexpected_error(e, channel)
  end

  private

  def should_fetch_email?(channel)
    channel.imap_enabled? && !channel.reauthorization_required?
  end

  def handle_unexpected_error(error, channel)
    Rails.logger.error "[IMAP::FETCH_EMAIL_SERVICE] Unexpected error for inbox #{channel.inbox.id} : #{error.class} - #{error.message}"
    ChatwootExceptionTracker.new(error, account: channel.account).capture_exception
  end

  def fetch_mails_with_lock(channel, interval)
    inbox_id = channel.inbox.id
    key = format(::Redis::Alfred::EMAIL_MESSAGE_MUTEX, inbox_id: inbox_id)
    success = false
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Attempting lock for inbox #{inbox_id}"
    with_lock(key, 5.minutes) do
      Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Lock acquired for inbox #{inbox_id}"
      success = process_email_for_channel(channel, interval)
    end

    duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at).round(1)
    if success
      Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Job completed for inbox #{inbox_id} in #{duration}s"
    else
      Rails.logger.error "[IMAP::FETCH_EMAIL_SERVICE] Job completed with authorization error for inbox #{inbox_id} in #{duration}s"
    end
  end

  def log_skipped_fetch(channel)
    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Skipping fetch for #{channel.inbox.id} : " \
                      "imap_enabled: #{channel.imap_enabled?}, reauthorization_required: #{channel.reauthorization_required?}"
  end

  def process_email_for_channel(channel, interval)
    inbound_emails = if channel.microsoft?
                       Imap::MicrosoftFetchEmailService.new(channel: channel, interval: interval).perform
                     elsif channel.google?
                       Imap::GoogleFetchEmailService.new(channel: channel, interval: interval).perform
                     else
                       Imap::FetchEmailService.new(channel: channel, interval: interval).perform
                     end

    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetched #{inbound_emails.length} new emails for inbox #{channel.inbox.id}"

    inbound_emails.each do |inbound_mail|
      process_mail(inbound_mail, channel)
    end

    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Finished processing fetched emails for inbox #{channel.inbox.id}"
    true
  rescue OAuth2::Error => e
    Rails.logger.error "[IMAP::FETCH_EMAIL_SERVICE] OAuth error for inbox #{channel.inbox.id} : #{e.message}"
    channel.authorization_error!
    false
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
    GlobalConfigService.load('EMAIL_PROCESSING_TIMEOUT_SECONDS', 60).to_i
  end
end
