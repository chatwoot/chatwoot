class Imap::MicrosoftFetchEmailService < Imap::BaseFetchEmailService
  def fetch_emails
    return if channel.provider_config['access_token'].blank?

    fetch_mail_for_channel
  end

  def store_in_imap(mail_object)
    imap = Net::IMAP.new(channel.imap_address, port: channel.imap_port, ssl: true)
    imap.authenticate(authentication_type, channel.imap_login, imap_password)
    imap.select('INBOX.Sent')
    imap_email = mail_object.encoded
    imap.append('INBOX.Sent', imap_email, [:Seen], Time.now)
    terminate_imap_connection
  end

  private

  def authentication_type
    'XOAUTH2'
  end

  def imap_password
    Microsoft::RefreshOauthTokenService.new(channel: channel).access_token
  end
end
