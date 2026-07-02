# Obtém um access token específico para a Microsoft Graph API.
# O token OAuth guardado é para outlook.office.com (IMAP); a Graph precisa de um
# token com audience https://graph.microsoft.com — então trocamos o refresh_token
# por um token Graph a cada envio.
# Credenciais do app resolvidas POR CONTA (com fallback global) — modelo híbrido.
# Ref: https://learn.microsoft.com/en-us/graph/api/user-sendmail
class Microsoft::GraphTokenService
  pattr_initialize [:channel!]

  def access_token
    refresh_for_graph_api
  end

  private

  def refresh_for_graph_api
    response = Net::HTTP.post_form(URI(token_url), token_params)

    raise_token_error(response) unless response.code.to_i == 200

    body = JSON.parse(response.body)
    # A Microsoft pode ROTACIONAR o refresh_token. Persistir o novo evita que o
    # IMAP de entrada (Microsoft::RefreshOauthTokenService) fique com um token velho/inválido.
    persist_rotated_refresh_token(body['refresh_token'])
    body['access_token']
  end

  def persist_rotated_refresh_token(new_refresh_token)
    return if new_refresh_token.blank?
    return if new_refresh_token == provider_config['refresh_token']

    config = channel.provider_config.to_h
    config['refresh_token'] = new_refresh_token
    channel.update!(provider_config: config)
  end

  def token_params
    {
      client_id: creds[:client_id],
      client_secret: creds[:client_secret],
      refresh_token: provider_config['refresh_token'],
      grant_type: 'refresh_token',
      scope: ::Microsoft::Scopes::GRAPH
    }
  end

  # Endpoint tenant-aware (app single-tenant falha no /common — AADSTS50194).
  def token_url
    ::EmailOauth::MicrosoftTenant.token_url(creds)
  end

  def creds
    @creds ||= ::EmailOauth::CredentialResolver.new(channel.account, 'microsoft').credentials
  end

  # Detalhe do provedor só nos logs; ao chamador (e ao status de falha da mensagem)
  # vai um código estável — não vaza error_description cru.
  def raise_token_error(response)
    detail = begin
      JSON.parse(response.body)['error_description']
    rescue JSON::ParserError, TypeError
      nil
    end
    Rails.logger.error("Microsoft Graph token refresh failed (#{response.code}): #{detail}")
    raise StandardError, "graph_token_refresh_failed (#{response.code})"
  end

  def provider_config
    @provider_config ||= channel.provider_config.with_indifferent_access
  end
end
