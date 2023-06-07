require 'net/imap'

class Inboxes::FetchImapEmailsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(channel)
    return unless should_fetch_email?(channel)

    process_email_for_channel(channel)
  rescue *ExceptionList::IMAP_EXCEPTIONS => e
    Rails.logger.error e
    channel.authorization_error!
  rescue EOFError, OpenSSL::SSL::SSLError, Net::IMAP::NoResponseError => e
    Rails.logger.error e
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
    last_email_time = DateTime.parse(Net::IMAP.format_datetime(last_email_time(channel)))

    received_mails(imap_inbox).each do |message_id|
      inbound_mail = Mail.read_from_string imap_inbox.fetch(message_id, 'RFC822')[0].attr['RFC822']

      Rails.logger.info("Email id: #{inbound_mail.from} and message_source_id: #{inbound_mail.message_id}, message_id: #{message_id}")

      next if email_already_present?(channel, inbound_mail, last_email_time)

      process_mail(inbound_mail, channel)
    end
  end

  def email_already_present?(channel, inbound_mail, last_email_time)
    processed_email?(inbound_mail, last_email_time) || channel.inbox.messages.find_by(source_id: inbound_mail.message_id).present?
  end

  def received_mails(imap_inbox)
    imap_inbox.search(['BEFORE', tomorrow, 'SINCE', yesterday])
  end

  def processed_email?(current_email, last_email_time)
    return current_email.date < last_email_time if current_email.date.present?

    false
  end

  def fetch_mail_for_ms_provider(channel)
    return if channel.provider_config['access_token'].blank?

    access_token = valid_access_token channel

    return unless access_token

    imap_inbox = authenticated_imap_inbox(channel, access_token, 'XOAUTH2')

    process_mails(imap_inbox, channel)
  end

  def process_mails(imap_inbox, channel)
    received_mails(imap_inbox).each do |message_id|
      inbound_mail = Mail.read_from_string imap_inbox.fetch(message_id, 'RFC822')[0].attr['RFC822']

      Rails.logger.info("Email id: #{inbound_mail.from} and message_source_id: #{inbound_mail.message_id}, message_id: #{message_id}")

      next if channel.inbox.messages.find_by(source_id: inbound_mail.message_id).present?

      process_mail(inbound_mail, channel)
    end
  end

  def authenticated_imap_inbox(channel, access_token, auth_method)
    imap = Net::IMAP.new(channel.imap_address, channel.imap_port, true)
    imap.authenticate(auth_method, channel.imap_login, access_token)
    imap.select('INBOX')
    imap
  end

  def last_email_time(channel)
    # we are only checking for emails in last 2 day
    last_email_incoming_message = channel.inbox.messages.incoming.where('messages.created_at >= ?', 2.days.ago).last
    if last_email_incoming_message.present?
      time = last_email_incoming_message.content_attributes['email']['date']
      time ||= last_email_incoming_message.created_at.to_s
    end
    time ||= 1.hour.ago.to_s

    DateTime.parse(time)
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
  end

  # Making sure the access token is valid for microsoft provider
  def valid_access_token(channel)
    Microsoft::RefreshOauthTokenService.new(channel: channel).access_token
  end
end
