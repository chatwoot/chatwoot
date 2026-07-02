# Refer: https://learn.microsoft.com/en-us/entra/identity-platform/configurable-token-lifetimes
class Microsoft::RefreshOauthTokenService < BaseRefreshOauthTokenService
  private

  # Builds the OAuth strategy for Microsoft Graph.
  # Credenciais resolvidas pela CONTA do canal (com fallback global).
  # client_options tenant-aware: app single-tenant renova no endpoint do
  # tenant (o /common fixo da strategy falharia no refresh, ~1h após conectar).
  def build_oauth_strategy
    creds = ::EmailOauth::CredentialResolver.new(channel.account, 'microsoft').credentials
    ::MicrosoftGraphAuth.new(nil, creds[:client_id], creds[:client_secret],
                             client_options: {
                               site: ::EmailOauth::MicrosoftTenant::BASE_URL,
                               authorize_url: ::EmailOauth::MicrosoftTenant.authorize_url(creds),
                               token_url: ::EmailOauth::MicrosoftTenant.token_url(creds)
                             })
  end

  # Token IMAP é do recurso Outlook — fixa o escopo no refresh (Azure v2 multi-recurso).
  def refresh_params
    { scope: ::Microsoft::Scopes::IMAP }
  end
end
