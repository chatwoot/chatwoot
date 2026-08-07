# CUSTOMIZAÇÃO_SYNAPSEOS
# HTTP client puro para a API Avisa (https://www.avisaapi.com.br/api).
#
# Sem conhecimento de Chatwoot models — recebe credenciais no construtor e
# expõe métodos por endpoint. Errors levantam Whatsapp::Providers::AvisaClient::Error.
require 'base64'

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
    extract_send_result(response)
  end

  # POST /actions/sendMedia — endpoint unificado que aceita URL pública.
  # Avisa baixa o arquivo da URL e envia pro WhatsApp.
  # type ∈ %w[image video audio document]
  def send_media(number:, type:, file_url:, caption: nil, file_name: nil)
    body = { number: normalize_number(number), fileUrl: file_url, type: type }
    body[:message] = caption.to_s if caption.present?
    body[:fileName] = file_name.to_s if file_name.present?

    response = post('/actions/sendMedia', body)
    extract_send_result(response)
  end

  # POST /actions/sendImage — aceita data URI base64 (dispensa URL pública).
  def send_image_base64(number:, data_uri:, caption: nil)
    body = { number: normalize_number(number), image: data_uri }
    body[:message] = caption.to_s if caption.present?

    response = post('/actions/sendImage', body)
    extract_send_result(response)
  end

  # POST /actions/sendDocument — aceita data URI base64, fileName e caption.
  def send_document_base64(number:, data_uri:, file_name: nil, caption: nil)
    body = { number: normalize_number(number), document: data_uri }
    body[:fileName] = file_name.to_s if file_name.present?
    body[:caption] = caption.to_s if caption.present?

    response = post('/actions/sendDocument', body)
    extract_send_result(response)
  end

  # POST /actions/sendAudio — base64 puro (sem prefixo data:), formato OGG/Opus.
  def send_audio_base64(number:, base64_payload:)
    body = { number: normalize_number(number), audio: base64_payload }

    response = post('/actions/sendAudio', body)
    extract_send_result(response)
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

  # POST /message/download/audio — baixa o ÁUDIO inbound DECRIPTADO (base64).
  # O webhook inbound do Avisa não anexa o arquivo de áudio (.enc); este endpoint
  # entrega o conteúdo decriptado a partir do hash `audioMessage` do whatsmeow.
  # Retorna os bytes (String binária) ou nil se indisponível. Best-effort.
  def download_audio(audio_message)
    download_media(kind: 'audio', media_message: audio_message)
  end

  # POST /message/download/{kind} — baixa a mídia inbound DECRIPTADA (base64) a
  # partir dos metadados whatsmeow (mesmo mecanismo do áudio). kind ∈
  # audio|image|video|document|sticker. O webhook do Avisa nem sempre anexa o
  # binário (figurinha NUNCA vem inline; imagem/vídeo/documento às vezes não) —
  # este endpoint entrega o conteúdo a partir do hash da mensagem. Retorna os
  # bytes (String binária) ou nil (best-effort: o caller cai no placeholder
  # visível, sem regressão). Repro conv 254 (figurinha virava placeholder).
  def download_media(kind:, media_message:)
    m = media_message || {}
    body = {
      Url: m['URL'] || m['url'],
      DirectPath: m['directPath'],
      MediaKey: m['mediaKey'],
      Mimetype: m['mimetype'],
      FileEncSHA256: m['fileEncSHA256'],
      FileSHA256: m['fileSHA256'],
      FileLength: m['fileLength'].to_i
    }
    response = post("/message/download/#{kind}", body)
    b64 = extract_base64(response)
    if b64.blank?
      shape = response.is_a?(Hash) ? response.keys.inspect : response.class.name
      inner = response.is_a?(Hash) && response['data'].is_a?(Hash) ? " data.keys=#{response['data'].keys.inspect}" : ''
      Rails.logger.warn("[AVISA] download_media(#{kind}) sem base64 na resposta — shape=#{shape}#{inner}")
      return nil
    end

    Base64.decode64(b64.to_s.sub(/\Adata:[^,]+,/, ''))
  rescue Error => e
    Rails.logger.warn("[AVISA] download_media(#{kind}) falhou: #{e.message}")
    nil
  end

  private

  # Extrai { id:, timestamp: } da resposta de um /actions/send*. ROBUSTO ao
  # shape: a Avisa mudou o envelope (~jun/2026) de `data.response.data` para
  # `data.data` (mesmo shape do /instance/status e do download). O parser rígido
  # antigo parava de achar o `Id` → TODO envio ficava com id nil → marcado como
  # falha/preso (source_id null) MESMO tendo sido entregue (repro 26/06→30/06,
  # 100% das outgoing da Elisa). Espelha a estratégia do extract_base64.
  def extract_send_result(response)
    inner = response.dig('data', 'response', 'data') ||
            response.dig('data', 'data') ||
            (response.is_a?(Hash) ? response['data'] : nil)
    inner = {} unless inner.is_a?(Hash)
    id = inner['Id'].presence || inner['id'].presence || inner['messageId'].presence ||
         deep_find_id(response, 0)
    { id: id.presence, timestamp: inner['Timestamp'] || inner['timestamp'] }
  end

  # Chaves EXATAS do id da mensagem (não substring — evita casar 'Jid'/'code').
  MSG_ID_KEYS = %w[Id id ID messageId MessageId message_id].freeze

  # Busca recursiva do id da mensagem em qualquer shape (fallback do
  # extract_send_result). Só aceita string plausível de id de mensagem WhatsApp.
  def deep_find_id(obj, depth = 0)
    return nil if depth > 5

    case obj
    when Hash
      MSG_ID_KEYS.each do |k|
        v = obj[k]
        return v if v.is_a?(String) && v.length >= 8 && v.match?(%r{\A[A-Za-z0-9._:/@-]+\z})
      end
      obj.values.each do |v|
        found = deep_find_id(v, depth + 1)
        return found if found
      end
      nil
    when Array
      obj.each do |v|
        found = deep_find_id(v, depth + 1)
        return found if found
      end
      nil
    end
  end

  # Chaves prováveis do base64, checadas antes do fallback recursivo.
  B64_KEYS = %w[base64 Base64 b64 data Data file File media Media content Content buffer audio].freeze

  # A resposta do /message/download/audio varia de shape: {data: "<b64>"},
  # {data: {base64: "..."}}, {status, data: ...}, {Data: "..."} etc. (em prod
  # observamos {status, data} — confirmado no log). Em vez de fixar a chave,
  # busca recursivamente a 1ª string base64 plausível, priorizando B64_KEYS.
  def extract_base64(response)
    deep_find_base64(response, 0)
  end

  def deep_find_base64(obj, depth)
    return nil if depth > 5

    case obj
    when String
      stripped = obj.sub(/\Adata:[^,]+,/, '')
      stripped.length > 50 && stripped.match?(%r{\A[A-Za-z0-9+/=\s]+\z}) ? stripped : nil
    when Hash
      (obj.values_at(*B64_KEYS).compact + obj.values).each do |v|
        found = deep_find_base64(v, depth + 1)
        return found if found
      end
      nil
    when Array
      obj.each do |v|
        found = deep_find_base64(v, depth + 1)
        return found if found
      end
      nil
    end
  end

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
