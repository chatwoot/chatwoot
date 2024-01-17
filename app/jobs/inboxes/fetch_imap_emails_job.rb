require 'net/imap'

class Inboxes::FetchImapEmailsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(channel)
    return unless should_fetch_email?(channel)

    process_email_for_channel(channel)
  rescue *ExceptionList::IMAP_EXCEPTIONS => e
    Rails.logger.error e
    channel.authorization_error!
  rescue EOFError, OpenSSL::SSL::SSLError, Net::IMAP::NoResponseError, Net::IMAP::BadResponseError => e
    Rails.logger.error e
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
    channel.reauthorized!
  end

  def fetch_mail_for_channel(channel)
    imap_inbox = authenticated_imap_inbox(channel, channel.imap_password, 'PLAIN')

    fetch_message_ids(imap_inbox, channel).each do |message_id|
      next if email_already_present?(channel, message_id)

      inbound_mail = Mail.read_from_string(imap_inbox.fetch(message_id, 'RFC822')[0].attr['RFC822'])
      process_mail(inbound_mail, channel)
      mail_info_logger(channel, inbound_mail, message_id)
    end
  end

  def fetch_message_ids(imap_inbox, channel)
    uids = fetch_uids(imap_inbox)
    Rails.logger.info "FETCH_EMAILS_FROM: #{channel.email} - Found #{uids.length} emails \n\n\n\n"

    message_ids = []
    uids.each_slice(100).each do |batch|
      uid_fetched = imap_inbox.fetch(batch, 'BODY.PEEK[HEADER.FIELDS (MESSAGE-ID)]')
      uid_fetched.each do |data|
        message_id = data.attr['BODY[HEADER.FIELDS (MESSAGE-ID)]'].to_s.scan(/<(.+?)>/).flatten.first
        message_ids.push([data.seqno, message_id])
      end
    end

    message_ids
  end

  def fetch_uids(imap_inbox)
    imap_inbox.search(['BEFORE', tomorrow, 'SINCE', yesterday])
  end

  def email_already_present?(channel, message_id)
    channel.inbox.messages.exists?(source_id: message_id)
  end

  def fetch_mail_for_ms_provider(channel)
    return if channel.provider_config['access_token'].blank?

    access_token = valid_access_token(channel)
    return unless access_token

    imap_inbox = authenticated_imap_inbox(channel, access_token, 'XOAUTH2')
    process_mails(imap_inbox, channel)
  end

  def process_mails(imap_inbox, channel)
    received_mails(imap_inbox).each do |message_id|
      inbound_mail = Mail.read_from_string(imap_inbox.fetch(message_id, 'RFC822')[0].attr['RFC822'])
      next if email_already_present?(channel, inbound_mail.message_id)

      process_mail(inbound_mail, channel)
      mail_info_logger(channel, inbound_mail, message_id)
    end
  end

  def mail_info_logger(_channel, inbound_mail, message_id)
    return if Rails.env.test?

    Rails.logger.info("
    # {channel.provider} Email id: #{inbound_mail.from} and message_source_id: #{inbound_mail.message_id}, message_id: #{message_id}")
  end

  def authenticated_imap_inbox(channel, _access_token, _auth_method)
    imap = Net::IMAP.new(channel.imap_address, channel.imap_port, true)
    imap.authenticate('PLAIN', channel.imap_login, channel.imap_password)
    imap.select('INBOX')
    imap
  end

  def process_mail(inbound_mail, channel)
    Imap::ImapMailbox.new.process(inbound_mail, channel)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception
    Rails.logger.error("
      #{channel.provider} Email dropped: #{inbound_mail.from} and message_source_id: #{inbound_mail.message_id}")
  end

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
