require 'net/imap'

class Inboxes::FetchImapEmailsJob < MutexApplicationJob
  queue_as :scheduled_jobs

  def perform(channel)
    return unless should_fetch_email?(channel)

    key = format(::Redis::Alfred::EMAIL_MESSAGE_MUTEX, inbox_id: channel.inbox.id)
    with_lock(key, 5.minutes) do
      process_email_for_channel(channel)
    end
  rescue *ExceptionList::IMAP_EXCEPTIONS => e
    Rails.logger.error e
    channel.authorization_error!
  rescue EOFError, OpenSSL::SSL::SSLError, Net::IMAP::NoResponseError, Net::IMAP::BadResponseError, Net::IMAP::InvalidResponseError => e
    Rails.logger.error e
  rescue LockAcquisitionError
    Rails.logger.error "Lock failed for #{channel.inbox.id}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
  end

  private

  def should_fetch_email?(channel)
    channel.imap_enabled? && !channel.reauthorization_required?
  end

  def process_email_for_channel(channel)
    if channel.microsoft?
      fetch_mail_for_ms_provider(channel)
    else
      fetch_mail_for_channel(channel)
    end
    # clearing old failures like timeouts since the mail is now successfully processed
    channel.reauthorized!
  end

  def fetch_mail_for_channel(channel)
    imap_client = build_imap_client(channel, channel.imap_password, 'PLAIN')

    message_ids_with_seq = fetch_message_ids_with_sequence(imap_client, channel)
    message_ids_with_seq.each do |message_id_with_seq|
      process_message_id(channel, imap_client, message_id_with_seq)
    end
  end

  def process_message_id(channel, imap_client, message_id_with_seq)
    seq_no, message_id = message_id_with_seq

    return if email_already_present?(channel, message_id)

    # Fetch the original mail content using the sequence no
    mail_str = imap_client.fetch(seq_no, 'RFC822')[0].attr['RFC822']

    if mail_str.blank?
      Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetch failed for #{channel.email} with message-id <#{message_id}>."
      return
    end

    inbound_mail = build_mail_from_string(mail_str)
    mail_info_logger(channel, inbound_mail, seq_no)
    process_mail(inbound_mail, channel)
  end

  # Sends a FETCH command to retrieve data associated with a message in the mailbox.
  # You can send batches of message sequence number in `.fetch` method.
  def fetch_message_ids_with_sequence(imap_client, channel)
    seq_nums = fetch_available_mail_sequence_numbers(imap_client)

    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetching mails from #{channel.email}, found #{seq_nums.length}."

    message_ids_with_seq = []
    seq_nums.each_slice(10).each do |batch|
      # Fetch only message-id only without mail body or contents.
      batch_message_ids = imap_client.fetch(batch, 'BODY.PEEK[HEADER.FIELDS (MESSAGE-ID)]')

      # .fetch returns an array of Net::IMAP::FetchData or nil
      # (instead of an empty array) if there is no matching message.
      # Check
      if batch_message_ids.blank?
        Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetching the batch failed for #{channel.email}."
        next
      end

      batch_message_ids.each do |data|
        message_id = build_mail_from_string(data.attr['BODY[HEADER.FIELDS (MESSAGE-ID)]']).message_id
        message_ids_with_seq.push([data.seqno, message_id])
      end
    end

    message_ids_with_seq
  end

  # Sends a SEARCH command to search the mailbox for messages that were
  # created between yesterday and today and returns message sequence numbers.
  # Return <message set>
  def fetch_available_mail_sequence_numbers(imap_client)
    imap_client.search(['BEFORE', tomorrow, 'SINCE', yesterday])
  end

  def fetch_mail_for_ms_provider(channel)
    return if channel.provider_config['access_token'].blank?

    access_token = valid_access_token channel

    return unless access_token

    imap_client = build_imap_client(channel, access_token, 'XOAUTH2')
    process_mails(imap_client, channel)
  end

  def process_mails(imap_client, channel)
    fetch_available_mail_sequence_numbers(imap_client).each do |seq_no|
      inbound_mail = Mail.read_from_string imap_client.fetch(seq_no, 'RFC822')[0].attr['RFC822']

      mail_info_logger(channel, inbound_mail, seq_no)

      next if channel.inbox.messages.find_by(source_id: inbound_mail.message_id).present?

      process_mail(inbound_mail, channel)
    end
  end

  def mail_info_logger(channel, inbound_mail, uid)
    return if Rails.env.test?

    Rails.logger.info("
      #{channel.provider} Email id: #{inbound_mail.from} - message_source_id: #{inbound_mail.message_id} - sequence id: #{uid}")
  end

  def build_imap_client(channel, access_token, auth_method)
    imap = Net::IMAP.new(channel.imap_address, channel.imap_port, true)
    imap.authenticate(auth_method, channel.imap_login, access_token)
    imap.select('INBOX')
    imap
  end

  def email_already_present?(channel, message_id)
    channel.inbox.messages.find_by(source_id: message_id).present?
  end

  def build_mail_from_string(raw_email_content)
    Mail.read_from_string(raw_email_content)
  end

  def process_mail(inbound_mail, channel)
    Imap::ImapMailbox.new.process(inbound_mail, channel)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
    Rails.logger.error("
      #{channel.provider} Email dropped: #{inbound_mail.from} and message_source_id: #{inbound_mail.message_id}")
  end

  # Making sure the access token is valid for microsoft provider
  def valid_access_token(channel)
    Microsoft::RefreshOauthTokenService.new(channel: channel).access_token
  end

  def yesterday
    (Time.zone.today - 1).strftime('%d-%b-%Y')
  end

  def tomorrow
    (Time.zone.today + 1).strftime('%d-%b-%Y')
  end
end
