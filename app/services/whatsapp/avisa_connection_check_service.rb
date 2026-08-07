# CUSTOMIZAÇÃO_SYNAPSEOS
# Checa a conexão da instância Avisa de um canal WhatsApp e registra o resultado
# em provider_config['last_connection_check'] (pra UI ler sem re-checar).
# Usado pelo job agendado (3x/dia) e pelo botão "Verificar agora" nas Configurações.
#
# Status possíveis: 'connected' | 'disconnected' | 'unknown' (indeterminado —
# 5xx/timeout; não afirma queda pra não gerar alarme falso).
# RESSALVA: pega desconexão REAL da instância, NÃO o erro 463 de reachout-lock
# (envio a frio travado com a instância "conectada"). Ver Whatsapp::Providers::AvisaClient#instance_status.
class Whatsapp::AvisaConnectionCheckService
  pattr_initialize [:channel!]

  Result = Struct.new(:status, :connected, :http, :checked_at, :raw, keyword_init: true)

  # Avisa os admins da conta (toast em tempo real) que a instância caiu.
  # Broadcast isolado — NÃO usa o pipeline de Notification (acoplado a conversa).
  # Front trata o evento 'whatsapp.instance_disconnected' em helper/actionCable.js.
  def self.broadcast_disconnected(channel, result)
    account = channel.account
    tokens = account.administrators.pluck(:pubsub_token)
    return if tokens.blank?

    ActionCableBroadcastJob.perform_later(
      tokens,
      'whatsapp.instance_disconnected',
      {
        account_id: account.id,
        inbox_id: channel.inbox&.id,
        inbox_name: channel.inbox&.name,
        status: result.status,
        checked_at: result.checked_at.iso8601
      }
    )
  end

  def perform
    raw = client.instance_status
    result = Result.new(
      status: status_from(raw[:connected]),
      connected: raw[:connected],
      http: raw[:http],
      checked_at: Time.current,
      raw: raw[:raw]
    )
    persist(result)
    result
  end

  private

  def client
    @client ||= Whatsapp::Providers::AvisaClient.new(
      api_key: channel.provider_config['api_key'],
      base_url: channel.provider_config['base_url']
    )
  end

  def status_from(connected)
    return 'connected' if connected == true
    return 'disconnected' if connected == false

    'unknown'
  end

  # update_column: grava só o metadado, sem disparar callbacks do canal
  # (ex: re-registro de webhook no painel Avisa ao salvar provider_config).
  def persist(result)
    cfg = (channel.provider_config || {}).dup
    cfg['last_connection_check'] = {
      'status' => result.status,
      'http' => result.http,
      'checked_at' => result.checked_at.iso8601
    }
    channel.update_column(:provider_config, cfg)
  end
end
