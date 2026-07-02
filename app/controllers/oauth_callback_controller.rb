class OauthCallbackController < ApplicationController
  # Tokens/códigos têm 32+ chars alfanuméricos — redige antes de logar.
  SENSITIVE_VALUE = /[A-Za-z0-9_.-]{32,}/

  def show
    # Provedor voltou com erro (ex.: AADSTS50194 — app single-tenant no endpoint
    # /common) ou sem code: não há o que trocar por token. Antes isso caía no
    # rescue e virava redirect mudo para a home; agora loga e leva o admin de
    # volta às configurações de inbox com o código do erro.
    return handle_provider_error if params[:error].present? || oauth_code.blank?

    @response = oauth_client.auth_code.get_token(oauth_code, token_exchange_params)

    handle_response
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    Rails.logger.error("[OauthCallback] #{provider_name} failed: #{e.class}: #{sanitize_for_log(e.message)}")
    redirect_to error_redirect_path('token_exchange_failed')
  end

  # Provedores que precisam fixar o escopo de UM recurso na troca do code
  # (ex.: Microsoft v2, que recusa code multi-recurso sem `scope`) sobrescrevem isto.
  def token_exchange_params
    { redirect_uri: "#{base_url}/#{provider_name}/callback" }
  end

  private

  def handle_provider_error
    Rails.logger.error(
      "[OauthCallback] #{provider_name} provider error: #{sanitize_for_log(params[:error])} " \
      "#{sanitize_for_log(params[:error_description])}"
    )
    # O código AADSTS (quando presente) é o dado acionável — ex.: AADSTS50194
    # diz exatamente o que corrigir no app registration do Azure.
    error_code = params[:error_description].to_s[/AADSTS\d+/] || params[:error].presence || 'missing_code'
    redirect_to error_redirect_path(error_code)
  end

  # Erro visível: se o `state` resolve a conta, o admin volta pra tela de nova
  # inbox com o código do erro (o frontend mostra o alerta). Home ('/') fica
  # só para quando nem a conta é identificável.
  def error_redirect_path(error_code)
    acct = begin
      account
    rescue StandardError
      nil
    end
    return '/' if acct.nil?

    "/app/accounts/#{acct.id}/settings/inboxes/new?oauth_error=#{ERB::Util.url_encode(error_code.to_s.first(64))}"
  end

  def sanitize_for_log(value)
    value.to_s.gsub(SENSITIVE_VALUE, '<REDACTED>').first(500)
  end

  def handle_response
    inbox, already_exists = find_or_create_inbox

    return redirect_to app_onboarding_inbox_setup_url(account_id: account.id) if return_to == 'onboarding'

    if already_exists
      redirect_to app_email_inbox_settings_url(account_id: account.id, inbox_id: inbox.id)
    else
      redirect_to app_email_inbox_agents_url(account_id: account.id, inbox_id: inbox.id)
    end
  end

  def find_or_create_inbox
    channel_email = find_channel_by_email
    # we need this value to know where to redirect on sucessful processing of the callback
    channel_exists = channel_email.present?

    channel_email ||= create_channel_with_inbox
    update_channel(channel_email)

    # reauthorize channel, this code path only triggers when microsoft auth is successful
    # reauthorized will also update cache keys for the associated inbox
    channel_email.reauthorized!

    [channel_email.inbox, channel_exists]
  end

  def find_channel_by_email
    Channel::Email.find_by(email: users_data['email'], account: account)
  end

  def update_channel(channel_email)
    existing_config = channel_email.provider_config.to_h.with_indifferent_access
    refresh_token = parsed_body['refresh_token'].presence || existing_config[:refresh_token]

    attributes = {
      imap_login: imap_login_identity, imap_address: imap_address,
      imap_port: '993', imap_enabled: true,
      provider: provider_name,
      provider_config: {
        access_token: parsed_body['access_token'],
        refresh_token: refresh_token,
        expires_on: token_expires_on
      }
    }
    if calendar_scope_granted?
      attributes[:calendar_enabled] = true
      attributes[:calendar_scope_granted] = true
    end
    channel_email.update!(attributes)
  end

  # The provider returns the granted scopes in the token response; if calendar
  # access was granted, mark the mailbox calendar-capable so meetings can use it.
  def calendar_scope_granted?
    granted = parsed_body['scope'].to_s
    granted.include?('/auth/calendar') || granted.include?('Calendars.ReadWrite')
  end

  # Identity used as the IMAP/SMTP login (SASL XOAUTH2 `user=` field). Defaults to the
  # id_token's email claim; providers override when their server requires a different
  # claim (e.g. Microsoft SMTP requires UPN).
  def imap_login_identity
    users_data['email']
  end

  # Usa a expiração REAL do token (não um valor fixo de 1h, que causava refresh
  # desnecessário / falha quando o provedor devolve uma janela diferente).
  def token_expires_on
    return Time.at(@response.expires_at).utc.to_s if @response.respond_to?(:expires_at) && @response.expires_at.present?

    expires_in = parsed_body['expires_in'].to_i
    return (Time.current.utc + expires_in.seconds).to_s if expires_in.positive?

    (Time.current.utc + 1.hour).to_s
  end

  def provider_name
    raise NotImplementedError
  end

  def oauth_client
    raise NotImplementedError
  end

  def create_channel_with_inbox
    ActiveRecord::Base.transaction do
      channel_email = Channel::Email.create!(email: users_data['email'], account: account)

      account.inboxes.create!(
        account: account,
        channel: channel_email,
        name: users_data['name'] || fallback_name
      )
      channel_email
    end
  end

  def users_data
    decoded_token = JWT.decode parsed_body[:id_token], nil, false
    decoded_token[0]
  end

  # The sgid purpose carries the onboarding return hint (see
  # OauthAuthorizationController#state). Try the onboarding purpose first — a match
  # both resolves the account and records the return target — then fall back to the
  # default purpose used by every other caller.
  def account_from_signed_id
    raise ActionController::BadRequest, 'Missing state variable' if params[:state].blank?

    if (account = GlobalID::Locator.locate_signed(params[:state], for: 'onboarding'))
      @return_to = 'onboarding'
    else
      account = GlobalID::Locator.locate_signed(params[:state])
    end

    raise 'Invalid or expired state' if account.nil?

    account
  end

  def account
    @account ||= account_from_signed_id
  end

  def return_to
    account # resolving the sgid records which purpose matched
    @return_to
  end

  # Conta usada para resolver as credenciais OAuth por conta (com fallback global).
  # No callback ela vem do `state` assinado — mesmo callback global de sempre.
  def oauth_account
    account
  end

  # Fallback name, for when name field is missing from users_data
  def fallback_name
    users_data['email'].split('@').first.parameterize.titleize
  end

  def oauth_code
    params[:code]
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  def parsed_body
    @parsed_body ||= @response.response.parsed
  end
end
