# CUSTOMIZAÇÃO_SYNAPSEOS
# HTTP client puro para a API Avisa (https://www.avisaapi.com.br/api).
#
# Sem conhecimento de Chatwoot models — recebe credenciais no construtor e
# expõe métodos por endpoint. Errors levantam Whatsapp::Providers::AvisaClient::Error.
class Whatsapp::Providers::AvisaClient
  DEFAULT_BASE_URL = 'https://www.avisaapi.com.br/api'.freeze

  Error = Class.new(StandardError)

  def initialize(api_key:, base_url: nil)
    @api_key = api_key
    @base_url = base_url.presence || DEFAULT_BASE_URL
  end

  # POST /actions/sendMessage
  # Retorna hash com { id:, timestamp: } em caso de sucesso.
  def send_text(number:, message:)
    response = post('/actions/sendMessage', { number: normalize_number(number), message: message.to_s })
    inner = response.dig('data', 'response', 'data') || {}
    { id: inner['Id'], timestamp: inner['Timestamp'] }
  end

  # POST /actions/sendMedia — endpoint unificado que aceita URL pública.
  # Avisa baixa o arquivo da URL e envia pro WhatsApp.
  # type ∈ %w[image video audio document]
  def send_media(number:, type:, file_url:, caption: nil, file_name: nil)
    body = { number: normalize_number(number), fileUrl: file_url, type: type }
    body[:message] = caption.to_s if caption.present?
    body[:fileName] = file_name.to_s if file_name.present?

    response = post('/actions/sendMedia', body)
    inner = response.dig('data', 'response', 'data') || {}
    { id: inner['Id'], timestamp: inner['Timestamp'] }
  end

  # POST /user/parselid — resolve LID (ex: "12345@lid") pra JID real.
  # Retorna string do JID (ex: "553491304735@s.whatsapp.net") ou nil.
  def parse_lid(lid:)
    response = post('/user/parselid', { lid: lid })
    response.dig('data', 'jid') || response['jid']
  rescue Error => e
    Rails.logger.warn("[AVISA] parse_lid falhou: #{e.message}")
    nil
  end

  # POST /webhook — registra URL de inbound no painel da Avisa pra essa instância.
  def register_webhook(webhook_url:)
    post('/webhook', { webhook: webhook_url })
    true
  end

  private

  def post(path, body)
    response = HTTParty.post(
      "#{@base_url}#{path}",
      headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{@api_key}" },
      body: body.to_json,
      timeout: 30
    )
    raise Error, "HTTP #{response.code}: #{response.body.to_s.truncate(200)}" unless response.success?

    response.parsed_response || {}
  end

  # Avisa aceita dígitos puros no campo `number` (sem `@s.whatsapp.net`, sem `+`).
  def normalize_number(raw)
    raw.to_s.split('@').first.to_s.tr('^0-9', '')
  end
end
