module MicrosoftConcern
  extend ActiveSupport::Concern

  def microsoft_client
    creds = ::EmailOauth::CredentialResolver.new(oauth_account, 'microsoft').credentials

    # Endpoint tenant-aware: app single-tenant da conta usa o tenant cadastrado
    # (AADSTS50194 no /common); sem tenant_id mantém /common.
    ::OAuth2::Client.new(creds[:client_id], creds[:client_secret],
                         {
                           site: ::EmailOauth::MicrosoftTenant::BASE_URL,
                           authorize_url: ::EmailOauth::MicrosoftTenant.authorize_url(creds),
                           token_url: ::EmailOauth::MicrosoftTenant.token_url(creds)
                         })
  end

  private

  def scope
    # IMAP.AccessAsUser.All: entrada (IMAP). Graph Mail.Send/ReadWrite: saída via Graph
    # (substitui o SMTP.Send, imune ao Security Defaults). Calendars.ReadWrite é SEMPRE
    # solicitado (agenda = capacidade da caixa Microsoft), num único consentimento.
    parts = [
      'offline_access',
      'https://outlook.office.com/IMAP.AccessAsUser.All',
      'https://graph.microsoft.com/Mail.Send',
      'https://graph.microsoft.com/Mail.ReadWrite',
      'openid profile email'
    ]
    parts << 'https://graph.microsoft.com/Calendars.ReadWrite' if request_calendar_scope?
    parts.join(' ')
  end

  # Calendar is a first-class capability of every Microsoft mailbox connection: the scope is
  # always requested (single consent) unless a self-hosted install explicitly disables it via
  # EMAIL_OAUTH_CALENDAR_SCOPE_ENABLED (distinct from the CRM meetings product flag).
  def request_calendar_scope?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('EMAIL_OAUTH_CALENDAR_SCOPE_ENABLED', true))
  end
end
