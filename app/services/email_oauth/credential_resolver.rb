module EmailOauth
  # Resolve as credenciais do app OAuth de e-mail para uma conta:
  # 1) usa o app cadastrado NA CONTA, se houver;
  # 2) senão, cai no app GLOBAL (super admin / ENV).
  # É o coração do modelo híbrido — o callback continua sendo o global de sempre,
  # só muda QUAL credencial é usada (resolvida pela conta vinda do `state`).
  class CredentialResolver
    GLOBAL_KEYS = {
      'microsoft' => { id: 'AZURE_APP_ID', secret: 'AZURE_APP_SECRET' },
      'google' => { id: 'GOOGLE_OAUTH_CLIENT_ID', secret: 'GOOGLE_OAUTH_CLIENT_SECRET' }
    }.freeze

    def initialize(account, provider)
      @account = account
      @provider = provider.to_s
    end

    # Resolução ATÔMICA: usa o app da conta SÓ quando id E secret estão presentes;
    # caso contrário, fallback global COMPLETO. Nunca mistura (id da conta + secret global).
    def credentials
      app = usable_account_app
      if app
        # tenant_id (settings) viaja junto com a credencial da conta: app
        # single-tenant usa o endpoint específico; global/multi-tenant fica nil
        # e os consumidores caem no /common (EmailOauth::MicrosoftTenant).
        { client_id: app.client_id, client_secret: app.client_secret, redirect_uri: app.redirect_uri.presence,
          tenant_id: app.tenant_id.presence, source: 'account' }
      else
        { client_id: global(:id), client_secret: global(:secret), redirect_uri: nil, tenant_id: nil, source: 'global' }
      end
    end

    def configured?
      creds = credentials
      creds[:client_id].present? && creds[:client_secret].present?
    end

    private

    def per_account_app
      return nil if @account.nil?

      @account.email_oauth_apps.find_by(provider: @provider)
    end

    def usable_account_app
      app = per_account_app
      return nil if app.nil? || app.client_id.blank? || app.client_secret.blank?

      app
    end

    def global(key)
      config = GLOBAL_KEYS[@provider]
      return nil if config.nil?

      GlobalConfigService.load(config[key], nil)
    end
  end
end
