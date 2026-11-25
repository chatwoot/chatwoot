require 'net/imap'

class Imap::BaseFetchEmailService
  MAX_MESSAGES_PER_SYNC = 500
  # How often the cheap incremental sync gives way to the full date sweep. The sweep is
  # what catches anything the cursor could have stepped over: a message that failed to
  # process and got skipped, a UID the server reported out of band, a cursor written by
  # an older build. One hour bounds that exposure without giving back the savings.
  FULL_SWEEP_INTERVAL = 1.hour.to_i

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

  def mail_info_logger(inbound_mail, uid)
    return if Rails.env.test?

    Rails.logger.info("
      #{channel.provider} Email id: #{inbound_mail.from} - message_source_id: #{inbound_mail.message_id} - uid: #{uid}")
  end

  def email_already_present?(channel, message_id)
    # exists? avoids Message's default_scope ORDER BY, which full-scans large inboxes
    channel.inbox.messages.exists?(source_id: message_id) || deleted_message_tracker.deleted?(message_id)
  end

  def deleted_message_tracker
    @deleted_message_tracker ||= Imap::DeletedMessageTracker.new(inbox: channel.inbox)
  end

  def fetch_mail_for_channel
    collected = collect_message_ids(fetch_available_mail_uids)
    mails = collected[:entries].filter_map { |entry| process_message_id(entry) }
    # Only after the batch is built, and only through the UID actually looked at. A run
    # that dies halfway leaves the cursor where it was, so the next one re-reads the same
    # range: wasted bandwidth, never a gap.
    advance_cursor(collected)
    mails
  end

  # The cursor turns "list everything since yesterday" (thousands of headers, every
  # minute, to find a handful of new mails) into "list everything after UID N". The date
  # sweep still runs on FULL_SWEEP_INTERVAL, and every branch that cannot prove the
  # cursor still describes this mailbox falls back to it.
  def sync_plan
    @sync_plan ||= begin
      cursor = uid_cursor.read
      validity = mailbox_uid_validity

      if validity.nil? || cursor.nil? || cursor[:uid_validity] != validity ||
         cursor[:mailbox] != mailbox_identity ||
         Time.current.to_i - cursor[:swept_at].to_i >= FULL_SWEEP_INTERVAL
        { mode: :full, uid_validity: validity }
      else
        { mode: :incremental, uid_validity: validity, from_uid: cursor[:last_uid].to_i + 1 }
      end
    end
  end

  # UIDVALIDITY is the server's promise that UIDs still mean what they meant last time.
  # When it changes (or cannot be read at all) every stored UID is meaningless, so the
  # only safe reading is "no cursor".
  def mailbox_uid_validity
    imap_client # selects INBOX
    @mailbox_uid_validity ||= imap_client.responses('UIDVALIDITY') { |values| values&.last }
  rescue StandardError => e
    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Could not read UIDVALIDITY for #{channel.email}: #{e.message}"
    nil
  end

  def uid_cursor
    @uid_cursor ||= Imap::UidCursor.new(inbox: channel.inbox)
  end

  # UIDVALIDITY is scoped to a mailbox, not global: two different mailboxes can report the
  # same number. Since the host and login of a channel are editable, the cursor also has to
  # name the mailbox it was built from, or repointing an inbox would silently inherit a
  # high-water mark from the previous account.
  def mailbox_identity
    @mailbox_identity ||= Digest::SHA256.hexdigest(
      [channel.imap_address, channel.imap_port, channel.imap_login].join(':')
    )
  end

  def advance_cursor(collected)
    validity = sync_plan[:uid_validity]
    return if validity.blank?

    previous = uid_cursor.read
    # A cursor from another UIDVALIDITY generation (or another mailbox) describes UIDs that
    # no longer exist. Carrying anything from it forward would park the new generation above
    # every real UID, and only the hourly sweep would ever see mail again.
    reusable = reusable_cursor?(previous, validity)
    last_uid = [collected[:inspected_through].to_i, reusable ? previous[:last_uid].to_i : 0].max
    return if last_uid.zero?

    uid_cursor.write(uid_validity: validity, last_uid: last_uid, mailbox: mailbox_identity,
                     swept_at: next_swept_at(collected, previous, reusable))
  end

  # swept_at is the clock for "when did we last look at the whole window", so only a full
  # sweep that actually reached the end of that window may move it. A sweep cut short by
  # the message cap did not, and stamping it anyway is what turns a backlog into a one-hour
  # drip: the cursor can sit above the pending UIDs (it never moves backwards), so the
  # incremental polls in between cannot see them, and a large enough backlog ages out of
  # the SINCE window before the sweeps get to it.
  def next_swept_at(collected, previous, reusable)
    return Time.current if sync_plan[:mode] == :full && collected[:exhausted]

    reusable ? previous[:swept_at].to_i : 0
  end

  def reusable_cursor?(cursor, validity)
    cursor.present? && cursor[:uid_validity] == validity && cursor[:mailbox] == mailbox_identity
  end

  def process_message_id(entry)
    uid, message_id = entry

    if message_id.blank?
      Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Empty message id for #{channel.email} with uid <#{uid}>."
      return
    end

    return if email_already_present?(channel, message_id)

    # Fetch the original mail content by UID, which is stable across the connection
    # unlike the sequence number.
    # BODY.PEEK[] avoids RFC822 parser failures seen with some IMAP servers.
    mail_str = imap_client.uid_fetch(uid, 'BODY.PEEK[]')&.first&.attr&.dig('BODY[]')

    if mail_str.blank?
      Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetch failed for #{channel.email} with message-id <#{message_id}>."
      return
    end

    inbound_mail = build_mail_from_string(mail_str)
    mail_info_logger(inbound_mail, uid)
    inbound_mail
  end

  # Sends a FETCH command to retrieve data associated with a message in the mailbox.
  # You can send batches of UIDs in `.uid_fetch`.
  #
  # Returns the entries worth downloading, the highest UID whose header was actually
  # inspected, and whether the run reached the end of what it searched. The first two are
  # different numbers whenever the cap cuts the run short, and the cursor has to move by
  # the second one: everything past it was never looked at, so claiming it would hide those
  # messages from every later incremental poll and leave only the hourly sweep to find
  # them, 500 at a time, until they age out of the window.
  def collect_message_ids(uids)
    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetching mails from #{channel.email}, found #{uids.length} " \
                      "(#{sync_plan[:mode]} sync)."

    collected = { entries: [], inspected_through: nil }
    # Sorted before slicing, not only inside each batch: SEARCH is not required to answer in
    # ascending order, so a cap that stops on the first slice would leave lower UIDs sitting
    # under the cursor with no run that ever looks at them again. Ascending order is what
    # makes "inspected through N" a contiguous boundary instead of a mark with holes below it.
    uids.sort.each_slice(MAX_MESSAGES_PER_SYNC) do |batch|
      # Checked here too, and not only inside the batch, so a slice that ends exactly on the
      # cap does not pay for one more FETCH of up to 500 headers nobody will read.
      break if collected[:entries].length >= MAX_MESSAGES_PER_SYNC

      consume_header_batch(batch, collected)
    end

    # Exactly at the cap counts as "not exhausted": the run cannot tell whether the next UID
    # existed, and the cost of being wrong is one extra sweep, against a stalled backlog.
    collected.merge(exhausted: collected[:entries].length < MAX_MESSAGES_PER_SYNC)
  end

  # Walks one batch of headers, stopping the moment the sync limit is reached. Whatever is
  # left in the batch was never looked at, which is exactly what keeps the cursor from
  # claiming it.
  def consume_header_batch(batch, collected)
    headers = fetch_headers_for(batch)
    return if headers.blank?

    # Sorted again here because the server may answer a FETCH in any order, regardless of
    # the order the UIDs were asked in.
    headers.sort_by { |data| data.attr['UID'].to_i }.each do |data|
      if collected[:entries].length >= MAX_MESSAGES_PER_SYNC
        Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Reached MAX_MESSAGES_PER_SYNC=#{MAX_MESSAGES_PER_SYNC} " \
                          "for #{channel.email}, stopping sync."
        break
      end

      collected[:inspected_through] = data.attr['UID'] || collected[:inspected_through]
      entry = build_message_id_entry(data)
      collected[:entries].push(entry) if entry
    end
  end

  def fetch_headers_for(batch)
    # Fetch only message-id only without mail body or contents.
    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Starting header batch of #{batch.length} for #{channel.email}"
    headers = imap_client.uid_fetch(batch, %w[UID BODY.PEEK[HEADER]])
    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetching the batch for #{channel.email}. Found #{headers&.length} messages."

    # .uid_fetch returns an array of Net::IMAP::FetchData or nil
    # (instead of an empty array) if there is no matching message.
    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] Fetching the batch failed for #{channel.email}." if headers.blank?

    headers
  end

  def build_message_id_entry(data)
    uid = data.attr['UID']
    return nil if uid.blank?

    mail = build_mail_from_string(data.attr['BODY[HEADER]'])
    return nil if MailPresenter.new(mail, channel.account).notification_email_from_chatwoot?

    message_id = mail.message_id
    return nil if message_id.blank?
    return nil if email_already_present?(channel, message_id)

    [uid, message_id]
  end

  # Returns the UIDs worth looking at. The incremental branch is the whole point of the
  # cursor: asking for a UID range costs one small response, while the date branch makes
  # the server list every message in the window on every run.
  def fetch_available_mail_uids
    return imap_client.uid_search(['SINCE', since]) if sync_plan[:mode] == :full

    from = sync_plan[:from_uid]
    # SequenceSet and not the plain string "N:*". net-imap serialises a bare String
    # argument as a quoted string, and Gmail answers a quoted sequence-set with
    # "Could not parse command" -- verified against the live server, where the mocked
    # client in the specs had happily accepted it.
    #
    # And `N:*` is not "UIDs at or above N": RFC 3501 makes `*` the highest UID in the
    # mailbox, so a range starting above it still matches that highest one and an idle
    # mailbox would keep handing back its last message forever. The filter is what makes
    # the range mean what it reads like.
    imap_client.uid_search(['UID', Net::IMAP::SequenceSet.new("#{from}:*")]).select { |uid| uid >= from }
  end

  def build_imap_client
    imap = Net::IMAP.new(channel.imap_address, port: channel.imap_port, ssl: channel.imap_enable_ssl)
    Imap::Authentication.authenticate!(imap, authentication_type, channel.imap_login, imap_password)

    imap.select('INBOX')
    Rails.logger.info "[IMAP::FETCH_EMAIL_SERVICE] IMAP connection established for #{channel.email}"
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
