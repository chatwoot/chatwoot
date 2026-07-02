# Resolve o tenant do endpoint Microsoft Identity a partir das credenciais
# resolvidas (EmailOauth::CredentialResolver#credentials). Apps single-tenant
# (caso comum em clientes corporativos) não funcionam no endpoint /common
# (AADSTS50194) — quando a conta cadastra um tenant_id, todas as chamadas
# (authorize, troca de code, refresh IMAP e token Graph) usam o endpoint
# específico; sem tenant_id, mantém /common (apps multi-tenant, app global).
module EmailOauth::MicrosoftTenant
  DEFAULT_TENANT = 'common'.freeze
  BASE_URL = 'https://login.microsoftonline.com'.freeze

  # Defesa em profundidade: mesmo formato validado no modelo. Valor fora do
  # padrão (GUID, domínio ou literais do Identity Platform) cai no /common em
  # vez de entrar cru na URL.
  def self.resolve(credentials)
    tenant = credentials[:tenant_id].to_s
    AccountEmailOauthApp::TENANT_ID_FORMAT.match?(tenant) ? tenant : DEFAULT_TENANT
  end

  def self.authorize_url(credentials)
    "#{BASE_URL}/#{resolve(credentials)}/oauth2/v2.0/authorize"
  end

  def self.token_url(credentials)
    "#{BASE_URL}/#{resolve(credentials)}/oauth2/v2.0/token"
  end
end
