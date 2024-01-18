require 'net/imap'

class Inboxes::FetchImapEmailsJob < MutexApplicationJob
  queue_as :scheduled_jobs

  def perform(channel)
    return unless should_fetch_email?(channel)

    with_lock(::Redis::Alfred::EMAIL_MESSAGE_MUTEX, inbox_id: channel.inbox.id) do
      process_email_for_channel(channel)
    end
  rescue *ExceptionList::IMAP_EXCEPTIONS => e
    Rails.logger.error e
    channel.authorization_error!
  rescue EOFError, OpenSSL::SSL::SSLError, Net::IMAP::NoResponseError, Net::IMAP::BadResponseError => e
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
    # fetching email for microsoft provider
    if channel.microsoft?
      fetch_mail_for_ms_provider(channel)
    else
      fetch_mail_for_channel(channel)
    end
    # clearing old failures like timeouts since the mail is now successfully processed
    channel.reauthorized!
  end

  def fetch_mail_for_channel(channel)
    imap_inbox = authenticated_imap_inbox(channel, channel.imap_password, 'PLAIN')

    fetch_message_ids(imap_inbox, channel).each do |message_id_uid_pair|
      uid, message_id = message_id_uid_pair
      next if email_already_present?(channel, message_id)

      inbound_mail = Mail.read_from_string(imap_inbox.fetch(uid, 'RFC822')[0].attr['RFC822'])
      mail_info_logger(channel, inbound_mail, uid)

      process_mail(inbound_mail, channel)
    end
  end

  def fetch_message_ids(imap_inbox, channel)
    uids = fetch_uids(imap_inbox)
    Rails.logger.info "FETCH_EMAILS_FROM: #{channel.email} - Found #{uids.length} emails \n\n\n\n"

    message_ids = []
    uids.each_slice(10).each do |batch|
      uid_fetched = imap_inbox.fetch(batch, 'BODY.PEEK[HEADER.FIELDS (MESSAGE-ID)]')
      # print uid_fetched
      uid_fetched.each do |data|
        message_id = data.attr['BODY[HEADER.FIELDS (MESSAGE-ID)]'].to_s.scan(/<(.+?)>/).flatten.first
        message_ids.push([data.seqno, message_id])
      end
    end

    message_ids
  end

  def email_already_present?(channel, message_id)
    channel.inbox.messages.find_by(source_id: message_id).present?
  end

  def fetch_uids(imap_inbox)
    imap_inbox.search(['BEFORE', tomorrow, 'SINCE', yesterday])
  end

  def fetch_mail_for_ms_provider(channel)
    return if channel.provider_config['access_token'].blank?

    access_token = valid_access_token channel

    return unless access_token

    imap_inbox = authenticated_imap_inbox(channel, access_token, 'XOAUTH2')

    process_mails(imap_inbox, channel)
  end

  def process_mails(imap_inbox, channel)
    fetch_uids(imap_inbox).each do |message_id|
      inbound_mail = Mail.read_from_string imap_inbox.fetch(message_id, 'RFC822')[0].attr['RFC822']

      mail_info_logger(channel, inbound_mail, message_id)

      next if channel.inbox.messages.find_by(source_id: inbound_mail.message_id).present?

      process_mail(inbound_mail, channel)
    end
  end

  def mail_info_logger(channel, inbound_mail, uid)
    return if Rails.env.test?

    Rails.logger.info("
      #{channel.provider} Email id: #{inbound_mail.from} - message_source_id: #{inbound_mail.message_id} - sequence id: #{uid}")
  end

  def authenticated_imap_inbox(channel, access_token, auth_method)
    imap = Net::IMAP.new(channel.imap_address, channel.imap_port, true)
    imap.authenticate(auth_method, channel.imap_login, access_token)
    imap.select('INBOX')
    imap
  end

  def yesterday
    (Time.zone.today - 1).strftime('%d-%b-%Y')
  end

  def tomorrow
    (Time.zone.today + 1).strftime('%d-%b-%Y')
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
end
