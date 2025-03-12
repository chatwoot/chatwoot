class Google::CallbacksController < OauthCallbackController
  include GoogleConcern

  def find_channel_by_email
    # find by imap_login first, and then by email
    # this ensures the legacy users can migrate correctly even if inbox email address doesn't match
    imap_channel = Channel::Email.find_by(imap_login: users_data['email'], account: account)
    return imap_channel if imap_channel

    Channel::Email.find_by(email: users_data['email'], account: account)
  end

  private

  def provider_name
    'google'
  end

  def imap_address
    'imap.gmail.com'
  end

  def oauth_client
    # from GoogleConcern
    google_client
  end
end
