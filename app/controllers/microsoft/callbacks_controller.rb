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

  # Exchange Online's SMTP AUTH (XOAUTH2) rejects proxy addresses in the SASL `user=` field;
  # it must match the token's UPN. `preferred_username` is the documented v2.0 claim;
  # `upn` is the v1.0 fallback.
  def imap_login_identity
    users_data['preferred_username'] || users_data['upn'] || super
  end
end
