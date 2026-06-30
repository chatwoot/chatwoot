# CUSTOMIZAÇÃO_SYNAPSEOS
# Recebe payload cru da Avisa API (whatsmeow/Baileys format) direto, sem passar
# pelo N8N. O webhook entrega em application/x-www-form-urlencoded (texto) ou
# multipart/form-data (mídia) com os campos:
#   - token: token da instância (autentica channel)
#   - jsonData: string JSON com o evento completo
#   - file: binário já descriptografado (quando mídia)
#
# Tipos de evento cobertos:
#   - texto: conversation, extendedTextMessage
#   - mídia: image/audio/video/document/sticker (com caption)
#   - reação: reactionMessage -> atualiza content_attributes da msg alvo
#   - edição: protocolMessage.editedMessage -> sobrescreve content da msg alvo
#   - quoted: extendedTextMessage.contextInfo -> popula in_reply_to_external_id
#   - outgoing echo: IsFromMe=true cria :outgoing (dedup por source_id)
# Grupos ainda pendentes.
# rubocop:disable Metrics/ClassLength -- parser coeso de eventos whatsmeow (texto/mídia/reação/edição/quoted).
class Whatsapp::IncomingMessageAvisaService
  pattr_initialize [:inbox!, :params!]

  MEDIA_KEYS = {
    'imageMessage' => :image,
    'videoMessage' => :video,
    'audioMessage' => :audio,
    'documentMessage' => :file,
    'stickerMessage' => :image
  }.freeze

  # kind do endpoint /message/download/{kind} do Avisa por tipo de mensagem
  # whatsmeow. Usado como fallback quando o webhook não anexa o binário inline.
  DOWNLOAD_KINDS = {
    'imageMessage' => 'image',
    'videoMessage' => 'video',
    'audioMessage' => 'audio',
    'documentMessage' => 'document',
    'stickerMessage' => 'sticker'
  }.freeze

  # Wrappers do whatsmeow que aninham a mensagem REAL em `.message`: mensagens
  # temporárias (ephemeralMessage), ver-uma-vez (viewOnce*), documento-com-
  # caption, envio de dispositivo vinculado (deviceSentMessage — WhatsApp Web/
  # Desktop) e o envelope FutureProof (associatedChildMessage). Texto/mídia
  # dentro deles caíam no placeholder "(text) não pôde ser exibido": conv 372
  # (ephemeral) e conv 381 (deviceSentMessage — cliente que manda do dispositivo
  # vinculado tinha TODO texto virando placeholder, em 24/06 e 29/06). extract_text/
  # media só olhavam o topo do Message; resolved_message desembrulha estes.
  WRAPPER_KEYS = %w[
    ephemeralMessage viewOnceMessage viewOnceMessageV2
    viewOnceMessageV2Extension documentWithCaptionMessage
    deviceSentMessage associatedChildMessage
  ].freeze

  def perform
    return if event.blank?
    return handle_reaction if reaction?
    return handle_edit if edit?
    return if source_id.present? && Message.exists?(source_id: source_id, inbox_id: inbox.id)

    phone = normalize_br_phone(phone_from_jid(resolved_jid))
    return if phone.blank?

    contact_inbox = build_contact_inbox(phone)
    conversation = find_or_create_conversation(contact_inbox)
    persist_message(conversation, contact_inbox.contact)
  end

  private

  def event
    @event ||= parse_json_data
  end

  def parse_json_data
    raw = params[:jsonData].to_s
    return {} if raw.blank?

    data = JSON.parse(raw)
    data['event'] || {}
  rescue JSON::ParserError => e
    Rails.logger.warn("[AVISA] jsonData parse failed: #{e.message}")
    {}
  end

  def from_me?
    event.dig('Info', 'IsFromMe') == true
  end

  def source_id
    @source_id ||= event.dig('Info', 'ID').to_s
  end

  # Se Chat vem com @lid (WhatsApp anonimizado), resolve pro JID real.
  # Prioridade: SenderAlt se já for @s.whatsapp.net; senão chama parselid da Avisa.
  def resolved_jid
    chat = event.dig('Info', 'Chat').to_s
    sender_alt = event.dig('Info', 'SenderAlt').to_s

    return chat unless chat.include?('@lid')
    return sender_alt if sender_alt.include?('@s.whatsapp.net')

    avisa_client.parse_lid(lid: chat).presence || sender_alt.presence || chat
  end

  def phone_from_jid(jid)
    jid.to_s.split('@').first.to_s.split(':').first.to_s.tr('^0-9', '')
  end

  # Avisa às vezes entrega o JID BR sem o 9º dígito do celular (55 + DDD + 8).
  # Canonicaliza pro formato COM 9 (número real) pra inbound e outbound
  # compartilharem o mesmo ContactInbox.source_id e não rachar a conversa.
  def normalize_br_phone(phone)
    digits = phone.to_s.tr('^0-9', '')
    match = digits.match(/\A55(\d{2})(\d{8})\z/)
    match ? "55#{match[1]}9#{match[2]}" : digits
  end

  def extract_text
    msg = resolved_message

    ext_text = msg.dig('extendedTextMessage', 'text')
    return ext_text if ext_text.present?

    return msg['conversation'] if msg['conversation'].present?

    # Respostas interativas (botão / template / lista): o texto que o cliente
    # escolheu não vem em conversation/extendedTextMessage.
    interactive = msg.dig('buttonsResponseMessage', 'selectedDisplayText') ||
                  msg.dig('templateButtonReplyMessage', 'selectedDisplayText') ||
                  msg.dig('listResponseMessage', 'title') ||
                  msg.dig('listResponseMessage', 'singleSelectReply', 'selectedRowId')
    return interactive if interactive.present?

    %w[imageMessage videoMessage documentMessage].each do |media_type|
      caption = msg.dig(media_type, 'caption')
      return caption if caption.present?
    end

    nil
  end

  # Desembrulha os WRAPPER_KEYS recursivamente (cap 5 níveis) e devolve a
  # mensagem efetiva — a real, de onde texto/mídia são extraídos. Sem wrapper,
  # devolve o próprio event['Message'] (comportamento idêntico ao anterior).
  def resolved_message
    @resolved_message ||= begin
      msg = event['Message'] || {}
      5.times do
        wrapper = WRAPPER_KEYS.find { |k| msg[k].is_a?(Hash) }
        break unless wrapper

        inner = msg[wrapper]['message'] || msg[wrapper]['Message']
        break unless inner.is_a?(Hash)

        msg = inner
      end
      msg
    end
  end

  def reaction?
    event.dig('Message', 'reactionMessage').is_a?(Hash)
  end

  def edit?
    event.dig('Message', 'protocolMessage', 'editedMessage').is_a?(Hash)
  end

  # ID (source_id) da mensagem alvo (reação/edição mira msg anterior pelo key.id).
  def target_message_source_id
    key = event.dig('Message', 'reactionMessage', 'key') if reaction?
    key ||= event.dig('Message', 'protocolMessage', 'key') if edit?
    return nil if key.blank?

    (key['id'] || key['ID']).to_s.presence
  end

  # extendedTextMessage.contextInfo.stanzaId referencia msg citada (in_reply_to).
  def quoted_external_id
    ctx = event.dig('Message', 'extendedTextMessage', 'contextInfo')
    return nil unless ctx.is_a?(Hash)

    (ctx['stanzaId'] || ctx['stanzaID']).to_s.presence
  end

  def handle_reaction
    target = find_target_message
    return if target.nil?

    emoji = event.dig('Message', 'reactionMessage', 'text').to_s
    sender_key = from_me? ? 'self' : phone_from_jid(resolved_jid).presence || 'unknown'
    target.update!(content_attributes: apply_reaction(target.content_attributes, sender_key, emoji))
  end

  def apply_reaction(current_attrs, sender_key, emoji)
    attrs = (current_attrs || {}).deep_dup
    attrs['external_reactions'] ||= {}

    if emoji.empty?
      attrs['external_reactions'].delete(sender_key)
      attrs.delete('external_reactions') if attrs['external_reactions'].empty?
    else
      attrs['external_reactions'][sender_key] = { 'emoji' => emoji, 'at' => Time.current.to_i }
    end
    attrs
  end

  def handle_edit
    target = find_target_message
    return if target.nil?

    edited = event.dig('Message', 'protocolMessage', 'editedMessage', 'Message') ||
             event.dig('Message', 'protocolMessage', 'editedMessage') || {}
    new_text = edited['conversation'].presence || edited.dig('extendedTextMessage', 'text').presence
    return if new_text.blank?

    attrs = (target.content_attributes || {}).deep_dup
    attrs['edited'] = true
    attrs['edited_at'] = Time.current.iso8601
    target.update!(content: new_text, content_attributes: attrs)
  end

  def find_target_message
    target_id = target_message_source_id
    return nil if target_id.blank?

    Message.find_by(source_id: target_id, inbox_id: inbox.id)
  end

  def build_contact_inbox(phone)
    ContactInboxWithContactBuilder.new(
      inbox: inbox,
      source_id: phone,
      contact_attributes: {
        name: event.dig('Info', 'PushName').presence || phone,
        phone_number: "+#{phone}"
      }
    ).perform
  end

  def persist_message(conversation, contact)
    text = extract_text
    media = media_attachment
    if text.blank? && media.blank?
      # CUSTOMIZAÇÃO_SYNAPSEOS: nunca deixar uma conversa-casca silenciosa
      # (conv 380). Um inbound sem texto e sem mídia anexável — áudio que não
      # baixou, ou tipo não suportado (localização, contato, enquete, figurinha
      # sem arquivo, etc.) — vira um placeholder VISÍVEL como incoming, pra a
      # equipe ver que o cliente mandou algo E o agente poder pedir reenvio.
      # Echo do próprio número (from_me) sem conteúdo é descartado como antes.
      return if from_me?

      text = unsupported_inbound_placeholder
    end

    message = conversation.messages.build(message_attributes(text, contact))
    attach_media(message, media) if media.present?
    message.save!
  end

  # Texto legível pro placeholder de inbound não exibível (sem texto/mídia).
  def unsupported_inbound_placeholder
    kind = case media_message_key
           when 'audioMessage' then 'um áudio'
           when 'imageMessage' then 'uma imagem'
           when 'videoMessage' then 'um vídeo'
           when 'documentMessage' then 'um documento'
           when 'stickerMessage' then 'uma figurinha'
           else
             tipo = event.dig('Info', 'Type').presence || event.dig('Info', 'MediaType').presence
             tipo ? "um conteúdo (#{tipo})" : 'um conteúdo'
           end
    "[O cliente enviou #{kind} que não pôde ser exibido aqui. Peça para reenviar por texto.]"
  end

  def message_attributes(text, contact)
    outgoing = from_me?
    content_attrs = outgoing ? { external_echo: true } : {}
    content_attrs[:in_reply_to_external_id] = quoted_external_id if quoted_external_id.present?

    {
      content: text,
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: outgoing ? :outgoing : :incoming,
      status: outgoing ? :delivered : :sent,
      sender: outgoing ? nil : contact,
      source_id: source_id,
      content_attributes: content_attrs
    }
  end

  def media_message_key
    msg = resolved_message
    MEDIA_KEYS.keys.find { |key| msg[key].is_a?(Hash) }
  end

  # Resolve a mídia a anexar como hash {io:, filename:, content_type:, file_type:}.
  # image/video/document/sticker: o Avisa entrega o binário em params[:file].
  # áudio (ptt/voice): o webhook NÃO anexa o arquivo — baixamos o áudio
  # decriptado da Avisa e anexamos. O anexo de áudio aciona a transcrição
  # NATIVA do Chatwoot (audio_transcriptions) e mostra o player + transcript.
  def media_attachment
    key = media_message_key
    return nil if key.blank?

    file = params[:file]
    if file.respond_to?(:original_filename) && file.respond_to?(:content_type)
      return {
        io: file.tempfile,
        filename: document_filename || file.original_filename,
        content_type: file.content_type,
        file_type: MEDIA_KEYS[key] || :file
      }
    end

    return downloaded_audio_attachment if key == 'audioMessage'

    # Avisa não inlinou o binário (figurinha sempre; imagem/vídeo/documento às
    # vezes). Baixa o conteúdo decriptado via /message/download/{kind} — mesmo
    # caminho do áudio. Best-effort: se falhar, cai no placeholder visível
    # (sem regressão vs. comportamento anterior). Repro conv 254.
    downloaded_media_attachment(key)
  end

  def downloaded_media_attachment(key)
    media = resolved_message[key] || {}
    bytes = avisa_client.download_media(kind: DOWNLOAD_KINDS[key], media_message: media)
    if bytes.blank?
      Rails.logger.warn("[AVISA] inbound #{key} source_id=#{source_id} download vazio — placeholder")
      return nil
    end
    Rails.logger.info("[AVISA] inbound #{key} source_id=#{source_id} download OK (#{bytes.bytesize} bytes) — anexando")

    {
      io: StringIO.new(bytes),
      filename: downloaded_media_filename(key, media),
      content_type: downloaded_media_content_type(key, media),
      file_type: MEDIA_KEYS[key] || :file
    }
  end

  def downloaded_media_filename(key, media)
    base = source_id.presence || 'arquivo'
    case key
    when 'documentMessage' then media['fileName'].to_s.presence || "documento-#{base}"
    when 'imageMessage'    then "imagem-#{base}.jpg"
    when 'videoMessage'    then "video-#{base}.mp4"
    when 'stickerMessage'  then "figurinha-#{base}.webp"
    else "arquivo-#{base}"
    end
  end

  def downloaded_media_content_type(key, media)
    mime = media['mimetype'].to_s.split(';').first.presence
    return mime if mime

    case key
    when 'imageMessage'   then 'image/jpeg'
    when 'videoMessage'   then 'video/mp4'
    when 'stickerMessage' then 'image/webp'
    else 'application/octet-stream'
    end
  end

  def downloaded_audio_attachment
    audio = resolved_message['audioMessage'] || {}
    Rails.logger.info("[AVISA] audio inbound source_id=#{source_id} baixando áudio decriptado (bytes esperados=#{audio['fileLength']})")
    bytes = avisa_client.download_audio(audio)
    if bytes.blank?
      Rails.logger.warn("[AVISA] audio inbound source_id=#{source_id} download_audio retornou vazio — mensagem NÃO criada")
      return nil
    end
    Rails.logger.info("[AVISA] audio inbound source_id=#{source_id} download_audio OK (#{bytes.bytesize} bytes) — anexando")

    {
      io: StringIO.new(bytes),
      filename: "audio-#{source_id.presence || 'voice'}.ogg",
      content_type: audio['mimetype'].to_s.split(';').first.presence || 'audio/ogg',
      file_type: :audio
    }
  end

  def document_filename
    resolved_message.dig('documentMessage', 'fileName').to_s.presence
  end

  def attach_media(message, media)
    message.attachments.new(
      account_id: message.account_id,
      file_type: media[:file_type],
      file: {
        io: media[:io],
        filename: media[:filename],
        content_type: media[:content_type]
      }
    )
  end

  # CUSTOMIZAÇÃO_SYNAPSEOS: respeita lock_to_single_conversation das inboxes de
  # agente (Alice/Angela). Sem isso, a 1ª resposta do cliente racha do histórico:
  # o backfill/disparo deixa a conversa `resolved`, e o filtro open/pending/snoozed
  # ignorava ela -> criava conversa nova. Com lock ligado, reusa a última conversa
  # do contato (qualquer status) e reabre se estava resolved — igual ao
  # ConversationBuilder nativo. Sem lock, mantém o filtro de status anterior.
  def find_or_create_conversation(contact_inbox)
    if inbox.lock_to_single_conversation
      existing = contact_inbox.conversations.order(created_at: :desc).first
      if existing
        existing.update!(status: :open) if existing.resolved?
        return existing
      end
    else
      conversation = contact_inbox.conversations
                                  .where(status: %w[open pending snoozed])
                                  .order(created_at: :desc)
                                  .first
      return conversation if conversation
    end

    Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id,
      additional_attributes: { source: 'avisa' }
    )
  end

  def avisa_client
    @avisa_client ||= Whatsapp::Providers::AvisaClient.new(
      api_key: inbox.channel.provider_config['api_key'],
      base_url: inbox.channel.provider_config['base_url']
    )
  end
end
# rubocop:enable Metrics/ClassLength
