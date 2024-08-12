class Google::CallbacksController < OauthCallbackController
  include GoogleConcern

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
