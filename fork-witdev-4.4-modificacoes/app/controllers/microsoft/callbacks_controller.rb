class Microsoft::CallbacksController < OauthCallbackController
  include MicrosoftConcern

  private

  def oauth_client
    microsoft_client
  end

  def provider_name
    'microsoft'
  end

  def imap_address
    'outlook.office365.com'
  end
end
