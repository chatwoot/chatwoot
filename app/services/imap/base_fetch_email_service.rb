require 'net/imap'

class Imap::BaseFetchEmailService
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
    channel.inbox.messages.find_by(source_id: message_id).present?
  end

  def fetch_mail_for_channel
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

    return if email_already_present?(channel, message_id)

    # Fetch the original mail content using the sequence no
    mail_str = imap_client.fetch(seq_no, 'RFC822')[0].attr['RFC822']

    if mail_str.blank?
      Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetch failed for #{channel.email} with message-id <#{message_id}>."
      return
    end

    inbound_mail = build_mail_from_string(mail_str)
    mail_info_logger(inbound_mail, seq_no)
    inbound_mail
  end

  # Sends a FETCH command to retrieve data associated with a message in the mailbox.
  # You can send batches of message sequence number in `.fetch` method.
  def fetch_message_ids_with_sequence
    seq_nums = fetch_available_mail_sequence_numbers

    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetching mails from #{channel.email}, found #{seq_nums.length}."

    message_ids_with_seq = []
    seq_nums.each_slice(10).each do |batch|
      # Fetch only message-id only without mail body or contents.
      batch_message_ids = imap_client.fetch(batch, 'BODY.PEEK[HEADER]')

      # .fetch returns an array of Net::IMAP::FetchData or nil
      # (instead of an empty array) if there is no matching message.
      # Check
      if batch_message_ids.blank?
        Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetching the batch failed for #{channel.email}."
        next
      end

      batch_message_ids.each do |data|
        message_id = build_mail_from_string(data.attr['BODY[HEADER]']).message_id
        message_ids_with_seq.push([data.seqno, message_id])
      end
    end

    message_ids_with_seq
  end

  # Sends a SEARCH command to search the mailbox for messages that were
  # created between yesterday (or given date) and today and returns message sequence numbers.
  # Return <message set>
  def fetch_available_mail_sequence_numbers
    imap_client.search(['SINCE', since])
  end

  def build_imap_client
    imap = Net::IMAP.new(channel.imap_address, port: channel.imap_port, ssl: true)
    imap.authenticate(authentication_type, channel.imap_login, imap_password)
    imap.select('INBOX')
    imap
  end

  def terminate_imap_connection
    imap_client.logout
  rescue Net::IMAP::Error => e
    Rails.logger.info "Logout failed for #{channel.email} - #{e.message}."
    imap_client.disconnect
  end

  def build_mail_from_string(raw_email_content)
    Mail.read_from_string(raw_email_content)
  end

  def since
    previous_day = Time.zone.today - (interval || 1).to_i
    previous_day.strftime('%d-%b-%Y')
  end
end
