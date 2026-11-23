require 'net/imap'

class Imap::BaseFetchEmailService
  include Imap::ConnectionRecovery

  MAX_MESSAGES_PER_SYNC = 500

  pattr_initialize [:channel!, :interval]

  def fetch_emails
    # Override this method
  end

  def perform
    inbound_emails = fetch_emails
    terminate_imap_connection

    inbound_emails
  end

  private

  def authentication_type
    # Override this method
  end

  def imap_password
    # Override this method
  end

  def imap_client
    @imap_client ||= build_imap_client
  end

  def mail_info_logger(inbound_mail, seq_no)
    return if Rails.env.test?

    Rails.logger.info("
      #{channel.provider} Email id: #{inbound_mail.from} - message_source_id: #{inbound_mail.message_id} - sequence id: #{seq_no}")
  end

  def email_already_present?(channel, message_id)
    # exists? avoids Message's default_scope ORDER BY, which full-scans large inboxes
    channel.inbox.messages.exists?(source_id: message_id) || deleted_message_tracker.deleted?(message_id)
  end

  def deleted_message_tracker
    @deleted_message_tracker ||= Imap::DeletedMessageTracker.new(inbox: channel.inbox)
  end

  def fetch_mail_for_channel
    @reconnect_attempts = 0
    @sequences_stale = false
    message_ids_with_seq = fetch_message_ids_with_sequence
    message_ids_with_seq.filter_map do |message_id_with_seq|
      process_message_id(message_id_with_seq)
    end
  end

  def process_message_id(message_id_with_seq)
    seq_no, message_id = message_id_with_seq

    if message_id.blank?
      Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Empty message id for #{channel.email} with seq no. <#{seq_no}>."
      return
    end

    return if @connection_lost
    return if email_already_present?(channel, message_id)

    # A message that already failed processing is not downloaded again on every
    # run. It is retried once the tracker's backoff has elapsed.
    return if failed_message?(message_id)

    seq_no = current_sequence_number(seq_no, message_id)
    return if seq_no.nil?

    # Fetch the original mail content using the sequence no.
    # BODY.PEEK[] avoids RFC822 parser failures seen with some IMAP servers.
    mail_str = fetch_full_message(seq_no, message_id)

    if mail_str.blank?
      Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetch failed for #{channel.email} with message-id <#{message_id}>."
      return
    end

    inbound_mail = build_mail_from_string(mail_str)
    mail_info_logger(inbound_mail, seq_no)
    inbound_mail
  end

  def failed_message?(message_id)
    return false unless failed_message_tracker.skip?(message_id)

    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Skipping previously failed email for #{channel.email} " \
                      "with message-id <#{message_id}>."
    true
  end

  def failed_message_tracker
    @failed_message_tracker ||= Imap::FailedMessageTracker.new(inbox: channel.inbox)
  end

  # Sends a FETCH command to retrieve data associated with a message in the mailbox.
  # You can send batches of message sequence number in `.fetch` method.
  def fetch_message_ids_with_sequence
    seq_nums = fetch_available_mail_sequence_numbers

    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetching mails from #{channel.email}, found #{seq_nums.length}."

    message_ids_with_seq = []
    seq_nums.each_slice(MAX_MESSAGES_PER_SYNC).each do |batch|
      append_message_ids_for_batch(batch, message_ids_with_seq)
      if message_ids_with_seq.length >= MAX_MESSAGES_PER_SYNC
        Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Reached MAX_MESSAGES_PER_SYNC=#{MAX_MESSAGES_PER_SYNC} for #{channel.email}, stopping sync."
        break
      end
    end

    message_ids_with_seq
  end

  def append_message_ids_for_batch(batch, message_ids_with_seq)
    # Fetch only message-id only without mail body or contents.
    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Starting header batch of #{batch.length} for #{channel.email}"
    batch_message_ids = imap_client.fetch(batch, 'BODY.PEEK[HEADER]')
    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetching the batch for #{channel.email}. Found #{batch_message_ids&.length} messages."

    # .fetch returns an array of Net::IMAP::FetchData or nil
    # (instead of an empty array) if there is no matching message.
    if batch_message_ids.blank?
      Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetching the batch failed for #{channel.email}."
      return
    end

    batch_message_ids.each do |data|
      entry = build_message_id_entry(data)
      next if entry.nil?

      message_ids_with_seq.push(entry)
      break if message_ids_with_seq.length >= MAX_MESSAGES_PER_SYNC
    end
  end

  def build_message_id_entry(data)
    mail = build_mail_from_string(data.attr['BODY[HEADER]'])
    return nil if MailPresenter.new(mail, channel.account).notification_email_from_chatwoot?

    message_id = mail.message_id
    return nil if message_id.blank?
    return nil if email_already_present?(channel, message_id)
    # Skip backed-off mail here so it does not consume the per-run sync cap;
    # healthy messages later in the mailbox still get their turn.
    return nil if failed_message?(message_id)

    [data.seqno, message_id]
  end

  # Sends a SEARCH command to search the mailbox for messages that were
  # created between yesterday (or given date) and today and returns message sequence numbers.
  # Return <message set>
  def fetch_available_mail_sequence_numbers
    imap_client.search(['SINCE', since])
  end

  def build_imap_client
    imap = Net::IMAP.new(channel.imap_address, port: channel.imap_port, ssl: channel.imap_enable_ssl)
    Imap::Authentication.authenticate!(imap, authentication_type, channel.imap_login, imap_password)

    imap.select('INBOX')
    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] IMAP connection established for #{channel.email}"
    imap
  rescue StandardError
    # Authentication or select failed after the socket was created; close the
    # client local to this call so it does not leak.
    imap&.disconnect
    raise
  end

  def terminate_imap_connection
    @imap_client&.logout
  rescue *TRANSIENT_IMAP_ERRORS => e
    Rails.logger.info "Logout failed for #{channel.email} - #{e.message}."
    disconnect_imap_client
  end

  def build_mail_from_string(raw_email_content)
    Mail.read_from_string(raw_email_content)
  end

  def since
    previous_day = Time.zone.today - (interval || 1).to_i
    previous_day.strftime('%d-%b-%Y')
  end
end
