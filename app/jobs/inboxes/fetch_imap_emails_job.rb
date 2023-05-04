require 'net/imap'

class Inboxes::FetchImapEmailsJob < ApplicationJob
  queue_as :low

  def perform(channel)
    return unless should_fetch_email?(channel)

    process_email_for_channel(channel)
  rescue *ExceptionList::IMAP_EXCEPTIONS
    channel.authorization_error!
  rescue EOFError => e
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
    imap = imap_authenticate(channel, channel.imap_password, 'PLAIN')
    last_email_time = DateTime.parse(Net::IMAP.format_datetime(last_email_time(channel)))

    received_mails(imap).each do |message_id|
      inbound_mail = Mail.read_from_string imap.fetch(message_id, 'RFC822')[0].attr['RFC822']

      next if processed_email?(inbound_mail, last_email_time)
      next if channel.inbox.messages.find_by(source_id: inbound_mail.message_id).present?

      process_mail(inbound_mail, channel)
    end
  end

  def received_mails(imap)
    imap.search(['BEFORE', tomorrow, 'SINCE', yesterday])
  end

  def processed_email?(current_email, last_email_time)
    current_email.date < last_email_time
  end

  def fetch_mail_for_ms_provider(channel)
    return if channel.provider_config['access_token'].blank?

    access_token = valid_access_token channel

    return unless access_token

    imap = imap_authenticate(channel, access_token, 'XOAUTH2')

    process_mails(imap, channel)
  end

  def process_mails(imap, channel)
    received_mails(imap).each do |message_id|
      inbound_mail = Mail.read_from_string imap.fetch(message_id, 'RFC822')[0].attr['RFC822']

      next if channel.inbox.messages.find_by(source_id: inbound_mail.message_id).present?

      process_mail(inbound_mail, channel)
    end
  end

  def imap_authenticate(channel, access_token, auth_method)
    imap = Net::IMAP.new(channel.imap_address, channel.imap_port, true)
    imap.authenticate(auth_method, channel.imap_login, access_token)
    imap.select('INBOX')
    imap
  end

  def last_email_time(channel)
    time = 1.hour.ago.to_s
    time = channel.inbox.messages.incoming.last.content_attributes['email']['date'] if channel.inbox.messages.any?
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
