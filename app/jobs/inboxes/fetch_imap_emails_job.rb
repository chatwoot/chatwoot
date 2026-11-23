require 'net/imap'

class Inboxes::FetchImapEmailsJob < MutexApplicationJob
  # Runs can legitimately exceed the default lock TTL when several emails hit the
  # processing timeout back to back, so the inbox lock has to outlive those runs.
  LOCK_TTL = 15.minutes

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
    with_lock(key, LOCK_TTL) do
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

  def failed_message_tracker(channel)
    @failed_message_tracker ||= Imap::FailedMessageTracker.new(inbox: channel.inbox)
  end

  def process_mail(inbound_mail, channel)
    # Skip if this email has failed multiple times recently
    if failed_message_tracker(channel).skip?(inbound_mail.message_id)
      Rails.logger.warn "[IMAP] Skipping problematic email: #{inbound_mail.message_id}"
      return
    end

    begin
      Timeout.timeout(email_processing_timeout) do
        Imap::ImapMailbox.new.process(inbound_mail, channel)
      end
    rescue Timeout::Error
      record_mail_processing_failure(inbound_mail, channel)
      Rails.logger.error "[IMAP] Email processing timeout (#{email_processing_timeout}s): #{inbound_mail.message_id}"
    rescue StandardError => e
      record_mail_processing_failure(inbound_mail, channel)
      Rails.logger.error "[IMAP] Failed to process email #{inbound_mail.message_id}: #{e.message}"
      ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
    end
  end

  def record_mail_processing_failure(inbound_mail, channel)
    failures = failed_message_tracker(channel).record_failure(inbound_mail.message_id)
    import_without_attachments(inbound_mail, channel) if failures >= Imap::FailedMessageTracker::MAX_FAILURES
  end

  # Once retries are exhausted the email keeps its place in the tracker, but instead of
  # failing silently the body is still delivered: attachments are the usual cause of
  # processing timeouts (large files, slow storage), so the mail is imported without
  # them and agents get a visible note in the conversation.
  def import_without_attachments(inbound_mail, channel)
    return if inbound_mail.attachments.blank?
    # A retry after a committed import must not claim it was degraded: the
    # stored message already exists and keeps its attachments.
    return if channel.inbox.messages.exists?(source_id: inbound_mail.message_id)

    strip_attachments!(inbound_mail)
    Timeout.timeout(email_processing_timeout) do
      Imap::ImapMailbox.new.process(inbound_mail, channel)
    end
    add_degraded_import_activity_message(channel, inbound_mail.message_id)
  rescue StandardError => e
    Rails.logger.error "[IMAP] Failed to import email without attachments #{inbound_mail.message_id}: #{e.message}"
  end

  # Mail's bang method only strips the top level, leaving attachments nested in
  # multipart/related parts; strip every multipart level before the retry.
  def strip_attachments!(mail)
    mail.parts.each { |part| strip_attachments!(part) if part.multipart? }
    mail.without_attachments!
  end

  def add_degraded_import_activity_message(channel, message_id)
    conversation = channel.inbox.messages.find_by(source_id: message_id)&.conversation
    return if conversation.blank?

    ::Conversations::ActivityMessageJob.perform_later(
      conversation,
      {
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :activity,
        content: I18n.t(
          'conversations.activity.email.imported_without_attachments',
          locale: conversation.account.locale
        )
      }
    )
  end

  def email_processing_timeout
    GlobalConfigService.load('EMAIL_PROCESSING_TIMEOUT_SECONDS', 60).to_i
  end
end
