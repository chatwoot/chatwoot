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

  # Prefer the actual `email` claim. Microsoft work/school accounts without a mailbox
  # omit it, returning only `preferred_username`/`upn`; fall back to those so inbox
  # creation does not fail on a null email.
  def email_address
    super || users_data['preferred_username'] || users_data['upn']
  end
end
