class Imap::MicrosoftFetchEmailService < Imap::BaseFetchEmailService
  def perform
    return if channel.provider_config['access_token'].blank?

    fetch_mail_for_channel
  end

  private

  def authentication_type
    'XOAUTH2'
  end

  def imap_password
    return if channel.provider_config['access_token'].blank?

    access_token = valid_access_token channel

    return unless access_token

    access_token
  end

  # Refresh the token before the emails are fetched
  def valid_access_token(channel)
    Microsoft::RefreshOauthTokenService.new(channel: channel).access_token
  end
end
