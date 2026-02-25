namespace :email do
  desc 'Import historical emails (sent & received) from Gmail IMAP into Chatwoot'
  task :import_history, [:channel_id, :days_back] => :environment do |_t, args|
    channel_id = args[:channel_id]
    days_back = (args[:days_back] || 180).to_i

    abort 'Usage: rake email:import_history[CHANNEL_ID,DAYS_BACK]' if channel_id.blank?

    channel = Channel::Email.find(channel_id)
    abort "Channel #{channel_id} not found" unless channel
    abort "Channel #{channel_id} is not a Google OAuth channel" unless channel.google?

    importer = EmailHistoryImporter.new(channel: channel, days_back: days_back)
    importer.perform
  end
end

class EmailHistoryImporter
  BATCH_SIZE = 50
  GMAIL_SENT_FOLDER = '[Gmail]/Sent Mail'.freeze
  GMAIL_INBOX_FOLDER = 'INBOX'.freeze

  attr_reader :channel, :days_back, :inbox, :account, :stats

  def initialize(channel:, days_back: 180)
    @channel = channel
    @days_back = days_back
    @inbox = channel.inbox
    @account = channel.account
    @stats = { inbox_fetched: 0, sent_fetched: 0, created: 0, skipped: 0, errors: 0 }
  end

  def perform
    log "Starting email history import for #{channel.email}"
    log "Importing last #{days_back} days (since #{since_date})"
    log "Account: #{account.name} (ID: #{account.id}), Inbox: #{inbox.name} (ID: #{inbox.id})"

    imap = connect_imap

    # Fetch from both folders, collecting all emails with metadata
    all_emails = []

    all_emails.concat(fetch_folder(imap, GMAIL_INBOX_FOLDER, :incoming))
    all_emails.concat(fetch_folder(imap, GMAIL_SENT_FOLDER, :outgoing))

    imap.logout
    imap.disconnect

    # Sort chronologically so threading works correctly
    all_emails.sort_by! { |e| e[:date] || Time.zone.at(0) }

    log "Total unique emails to process: #{all_emails.size}"

    # Deduplicate by message_id (same email can appear in both INBOX and Sent)
    seen_ids = Set.new
    all_emails = all_emails.reject do |email_data|
      mid = email_data[:message_id]
      if mid.present? && seen_ids.include?(mid)
        true
      else
        seen_ids.add(mid) if mid.present?
        false
      end
    end

    log "After dedup: #{all_emails.size} emails"

    all_emails.each_with_index do |email_data, idx|
      process_email(email_data)
      log "Progress: #{idx + 1}/#{all_emails.size}" if ((idx + 1) % 50).zero?
    end

    log "Import complete! #{stats}"
  end

  private

  def connect_imap
    access_token = Google::RefreshOauthTokenService.new(channel: channel).access_token
    imap = Net::IMAP.new('imap.gmail.com', port: 993, ssl: true)
    imap.authenticate('XOAUTH2', channel.imap_login.presence || channel.email, access_token)
    imap
  end

  def fetch_folder(imap, folder_name, direction)
    log "Fetching from #{folder_name}..."
    imap.select(folder_name)

    seq_nums = imap.search(['SINCE', since_date])
    log "Found #{seq_nums.size} emails in #{folder_name}"

    emails = []
    seq_nums.each_slice(BATCH_SIZE) do |batch|
      headers_data = imap.fetch(batch, 'BODY.PEEK[HEADER]')
      next if headers_data.blank?

      headers_data.each do |data|
        mail_header = Mail.read_from_string(data.attr['BODY[HEADER]'])
        message_id = mail_header.message_id

        # Skip if already in the system
        if message_id.present? && inbox.messages.exists?(source_id: message_id)
          stats[:skipped] += 1
          next
        end

        emails << {
          seq_no: data.seqno,
          message_id: message_id,
          direction: direction,
          folder: folder_name,
          date: mail_header.date&.to_time
        }
      end
    end

    stat_key = direction == :incoming ? :inbox_fetched : :sent_fetched
    stats[stat_key] = emails.size
    log "New emails to import from #{folder_name}: #{emails.size}"

    # Now fetch full RFC822 content for new emails
    fetch_full_content(imap, folder_name, emails)
  end

  def fetch_full_content(imap, folder_name, emails)
    return emails if emails.empty?

    # Re-select folder to ensure correct context
    imap.select(folder_name)

    emails.each_slice(BATCH_SIZE) do |batch|
      seq_nos = batch.map { |e| e[:seq_no] }
      full_data = imap.fetch(seq_nos, 'RFC822')
      next if full_data.blank?

      full_data.each do |data|
        email_entry = batch.find { |e| e[:seq_no] == data.seqno }
        next unless email_entry

        email_entry[:raw] = data.attr['RFC822']
      end
    end

    # Remove entries where we failed to fetch content
    emails.reject { |e| e[:raw].blank? }
  end

  def process_email(email_data)
    mail = Mail.read_from_string(email_data[:raw])
    processed_mail = MailPresenter.new(mail, account)

    # Skip auto-replies and bounces
    if processed_mail.auto_reply? || processed_mail.bounced?
      stats[:skipped] += 1
      return
    end

    # Skip if message_id already exists (extra safety check)
    if processed_mail.message_id.present? && inbox.messages.exists?(source_id: processed_mail.message_id)
      stats[:skipped] += 1
      return
    end

    ActiveRecord::Base.transaction do
      if email_data[:direction] == :incoming
        create_incoming_message(mail, processed_mail)
      else
        create_outgoing_message(mail, processed_mail)
      end
    end

    stats[:created] += 1
  rescue StandardError => e
    stats[:errors] += 1
    log "Error processing #{email_data[:message_id]}: #{e.message}"
  end

  def create_incoming_message(mail, processed_mail)
    contact, contact_inbox = find_or_create_contact(processed_mail.original_sender, sender_name(processed_mail))
    conversation = find_or_create_conversation(mail, processed_mail, contact, contact_inbox)

    create_message(
      conversation: conversation,
      processed_mail: processed_mail,
      message_type: :incoming,
      sender: contact,
      created_at: mail.date&.to_time
    )
  end

  def create_outgoing_message(mail, processed_mail)
    # For sent emails, the contact is the recipient
    recipient_email = extract_recipient_email(mail)
    return if recipient_email.blank?

    # Skip emails sent to ourselves
    return if recipient_email.downcase == channel.email.downcase

    contact, contact_inbox = find_or_create_contact(recipient_email, recipient_name(mail))
    conversation = find_or_create_conversation(mail, processed_mail, contact, contact_inbox)

    # Find the agent user who sent this (match by email)
    sender_user = account.users.find_by(email: channel.email) || account.users.find_by(email: processed_mail.original_sender)

    create_message(
      conversation: conversation,
      processed_mail: processed_mail,
      message_type: :outgoing,
      sender: sender_user,
      created_at: mail.date&.to_time
    )
  end

  def find_or_create_contact(email, name)
    return [nil, nil] if email.blank?

    email = email.downcase
    contact = inbox.contacts.from_email(email)

    if contact.present?
      contact_inbox = ContactInbox.find_by(inbox: inbox, contact: contact)
      [contact, contact_inbox]
    else
      contact_inbox = ContactInboxWithContactBuilder.new(
        source_id: email,
        inbox: inbox,
        contact_attributes: {
          name: name || email.split('@').first,
          email: email
        }
      ).perform
      [contact_inbox.contact, contact_inbox]
    end
  end

  def find_or_create_conversation(mail, processed_mail, contact, contact_inbox)
    # Try to find existing conversation by threading headers
    conversation = find_conversation_by_in_reply_to(processed_mail)
    conversation ||= find_conversation_by_references(mail)

    return conversation if conversation.present?

    Conversation.create!(
      account_id: account.id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      contact_inbox_id: contact_inbox&.id,
      additional_attributes: {
        source: 'email',
        in_reply_to: processed_mail.in_reply_to,
        mail_subject: processed_mail.subject,
        initiated_at: { timestamp: (mail.date&.to_time || Time.current).utc }
      }
    )
  end

  def find_conversation_by_in_reply_to(processed_mail)
    return if processed_mail.in_reply_to.blank?

    message = inbox.messages.find_by(source_id: processed_mail.in_reply_to)
    if message
      inbox.conversations.find_by(id: message.conversation_id)
    else
      inbox.conversations.find_by("additional_attributes->>'in_reply_to' = ?", processed_mail.in_reply_to)
    end
  end

  def find_conversation_by_references(mail)
    return if mail.references.blank?

    references = Array.wrap(mail.references)
    references.each do |ref_id|
      message = inbox.messages.find_by(source_id: ref_id)
      return inbox.conversations.find_by(id: message.conversation_id) if message.present?
    end

    nil
  end

  def create_message(conversation:, processed_mail:, message_type:, sender:, created_at:)
    content = mail_content(processed_mail)

    message = conversation.messages.create!(
      account_id: account.id,
      sender: sender,
      content: content&.truncate(150_000),
      inbox_id: inbox.id,
      message_type: message_type,
      content_type: :incoming_email,
      source_id: processed_mail.message_id,
      content_attributes: {
        email: processed_mail.serialized_data,
        cc_email: processed_mail.cc,
        bcc_email: processed_mail.bcc
      },
      created_at: created_at || Time.current
    )

    # Process attachments
    all_attachments = processed_mail.attachments.last(Message::NUMBER_OF_PERMITTED_ATTACHMENTS)
    all_attachments.each do |mail_attachment|
      attachment = message.attachments.new(account_id: account.id, file_type: 'file')
      attachment.file.attach(mail_attachment[:blob])
    end
    message.save! if all_attachments.any?
  end

  def mail_content(processed_mail)
    if processed_mail.text_content.present?
      processed_mail.text_content[:reply]
    elsif processed_mail.html_content.present?
      processed_mail.html_content[:reply]
    end
  end

  def extract_recipient_email(mail)
    to = mail.to
    return if to.blank?

    # Skip if only recipient is our own channel email
    recipients = Array.wrap(to).map(&:downcase)
    recipients.reject { |e| e == channel.email.downcase }.first || recipients.first
  end

  def sender_name(processed_mail)
    processed_mail.sender_name || processed_mail.from.first&.split('@')&.first
  end

  def recipient_name(mail)
    to_field = mail[:to]
    return unless to_field

    begin
      address = Mail::Address.new(to_field.value)
      address.name || address.address.split('@').first
    rescue StandardError
      mail.to&.first&.split('@')&.first
    end
  end

  def since_date
    (Time.zone.today - days_back).strftime('%d-%b-%Y')
  end

  def log(message)
    puts "[EmailHistoryImporter] #{message}"
    Rails.logger.info("[EmailHistoryImporter] #{message}")
  end
end
