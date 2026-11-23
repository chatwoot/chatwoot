module Imap::ConnectionRecovery
  # Reconnects a dropped IMAP session and keeps the message queue aligned with
  # the new session's sequence numbers.
  MAX_RECONNECT_ATTEMPTS = 3
  TRANSIENT_IMAP_ERRORS = [
    IOError, SystemCallError, SocketError, Timeout::Error,
    OpenSSL::SSL::SSLError, Net::IMAP::Error
  ].freeze

  private

  # When the IMAP connection drops mid-run (for example a server-side BYE),
  # reconnect and retry the message instead of aborting the whole batch. A
  # replacement session can drop too, so keep going until the reconnect budget
  # is spent.
  def fetch_full_message(seq_no, message_id)
    loop do
      return fetch_body(seq_no)
    rescue *TRANSIENT_IMAP_ERRORS => e
      return log_fetch_failure(seq_no, e) if @connection_lost

      unless reconnect_imap
        # A failed setup does not always spend the budget; keep trying until it
        # is actually exhausted.
        return log_fetch_failure(seq_no, e) if @connection_lost

        next
      end

      # Sequence numbers can shift on reconnect when another client expunges
      # mail, so re-resolve the message by its Message-ID header.
      seq_no = re_resolve_sequence_number(message_id)
      return if seq_no.nil?
    end
  end

  def fetch_body(seq_no)
    imap_client.fetch(seq_no, 'BODY.PEEK[]')&.first&.attr&.dig('BODY[]')
  end

  # A reconnect renumbers the mailbox, so every queued sequence number is stale
  # even when it still points at a message.
  def current_sequence_number(seq_no, message_id)
    return seq_no unless @sequences_stale

    re_resolve_sequence_number(message_id)
  end

  def re_resolve_sequence_number(message_id)
    seq_no = imap_client.search(['HEADER', 'Message-ID', message_id])&.first
    gone_message = "[IMAP::FETCH_EMAIL_SERVICE] Message <#{message_id}> gone after reconnect for #{channel.email}."
    Rails.logger.info(gone_message) if seq_no.nil?
    seq_no
  rescue *TRANSIENT_IMAP_ERRORS => e
    Rails.logger.error "[IMAP::FETCH_EMAIL_SERVICE] Re-resolve failed for #{channel.email} with message-id <#{message_id}>: #{e.message}"
    return nil unless reconnect_imap

    retry
  end

  def reconnect_imap
    return false if @connection_lost

    @reconnect_attempts += 1
    if @reconnect_attempts > MAX_RECONNECT_ATTEMPTS
      @connection_lost = true
      return false
    end

    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Reconnecting IMAP for #{channel.email} " \
                      "(attempt #{@reconnect_attempts}/#{MAX_RECONNECT_ATTEMPTS})"
    disconnect_imap_client
    @imap_client = build_imap_client
    @sequences_stale = true
    true
  rescue OAuth2::Error
    # Let the job mark the channel as requiring reauthorization.
    raise
  rescue StandardError => e
    @connection_lost = true if @reconnect_attempts >= MAX_RECONNECT_ATTEMPTS
    Rails.logger.error "[IMAP::FETCH_EMAIL_SERVICE] Reconnect failed for #{channel.email}: #{e.message}"
    false
  end

  def disconnect_imap_client
    @imap_client&.disconnect
  rescue StandardError
    nil
  end

  def log_fetch_failure(seq_no, error)
    Rails.logger.error "[IMAP::FETCH_EMAIL_SERVICE] Fetch failed for #{channel.email} with seq no. <#{seq_no}>: #{error.message}"
    nil
  end
end
