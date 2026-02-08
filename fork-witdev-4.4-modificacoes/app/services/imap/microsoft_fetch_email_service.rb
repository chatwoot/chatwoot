class Imap::MicrosoftFetchEmailService < Imap::BaseFetchEmailService
  def fetch_emails
    return if channel.provider_config['access_token'].blank?

    fetch_mail_for_channel
  end

  private

  def authentication_type
    'XOAUTH2'
  end

  def imap_password
    Microsoft::RefreshOauthTokenService.new(channel: channel).access_token
  end
end
