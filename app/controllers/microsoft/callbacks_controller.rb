class Microsoft::CallbacksController < OauthCallbackController
  include MicrosoftConcern

  private

  def oauth_client
    microsoft_client
  end

  # Azure v2: redime o code para o recurso Outlook (IMAP) — um recurso só, com
  # openid p/ id_token. O refresh_token resultante é multi-recurso; o envio troca-o
  # por um token Graph (Microsoft::GraphTokenService).
  def token_exchange_params
    super.merge(scope: ::Microsoft::Scopes::IMAP)
  end

  def provider_name
    'microsoft'
  end

  # Azure v2 mints an IMAP-scoped access token at the callback, so the token response never
  # echoes the calendar grant (unlike Google's single multi-scope token). Calendar is always
  # part of the consent when requested, and a successful callback means it was granted, so
  # mark the mailbox calendar-capable based on the requested scope instead of the token echo.
  def calendar_scope_granted?
    request_calendar_scope?
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
