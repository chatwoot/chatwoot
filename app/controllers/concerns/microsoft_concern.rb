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
    # (substitui o SMTP.Send, imune ao Security Defaults). Calendars.ReadWrite só é
    # somado quando a feature de reuniões está ligada (agenda = capacidade da caixa),
    # mantendo SEMPRE o escopo de e-mail completo (IMAP + openid) no consentimento.
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

  def request_calendar_scope?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('CRM_CALENDAR_MEETINGS_ENABLED', false)) || calendar_oauth_intent?
  end

  def calendar_oauth_intent?
    state_params = (session[:oauth_state_params] || {}).with_indifferent_access

    params[:calendar_intent].present? ||
      params[:intent].to_s == 'calendar' ||
      params[:oauth_intent].to_s == 'calendar' ||
      state_params[:calendar_intent].present? ||
      state_params[:intent].to_s == 'calendar' ||
      state_params[:oauth_intent].to_s == 'calendar'
  end
end
