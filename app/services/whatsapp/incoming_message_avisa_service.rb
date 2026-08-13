# CUSTOMIZAÇÃO_SYNAPSEOS
# Parser de inbound WhatsApp/Avisa portado do fork fykos-chat (versão mais completa
# do MESMO serviço) — preserva a nossa customização find_or_create_conversation
# (lock_to_single_conversation, inboxes de agente Alice/Angela) que o fykos não tem.
# Recebe payload cru da Avisa API (whatsmeow/Baileys format) direto, sem passar
# pelo N8N. O webhook entrega em application/x-www-form-urlencoded (texto) ou
# multipart/form-data (mídia) com os campos:
#   - token: token da instância (autentica channel)
#   - jsonData: string JSON com o evento completo
#   - file: binário já descriptografado (quando mídia)
#
# Tipos de evento cobertos:
#   - texto: conversation, extendedTextMessage
#   - mídia: image/audio/video/document/sticker (caption + download decriptado
#     via /message/download/{kind} quando o webhook não anexa inline)
#   - resposta interativa: botão/lista/flow (template/carrossel) -> texto = rótulo
#   - estruturado (resumo visível): localização, contato(s), enquete, evento
#   - reação: reactionMessage -> atualiza content_attributes da msg alvo
#   - edição: protocolMessage.editedMessage -> sobrescreve content da msg alvo
#   - envelopes (desembrulhados): ephemeral/view-once/doc-com-legenda/
#     deviceSent/associatedChild (FutureProof)
#   - quoted: extendedTextMessage.contextInfo -> popula in_reply_to_external_id
#   - resposta a STATUS: quoted de status@broadcast -> preserva a legenda
#     citada e NAO carimba o externalAdReply (que ali e a origem antiga da
#     thread, nao o assunto)
#   - outgoing echo: IsFromMe=true cria :outgoing (dedup por source_id)
#   - ruído de sistema: protocolMessage não-edição (revoke/sync) -> ignorado
# Grupos ainda pendentes.
# rubocop:disable Metrics/ClassLength -- parser coeso de eventos whatsmeow (texto/mídia/reação/edição/quoted).
class Whatsapp::IncomingMessageAvisaService
  pattr_initialize [:inbox!, :params!]

  MEDIA_KEYS = {
    'imageMessage' => :image,
    'videoMessage' => :video,
    # ptvMessage = vídeo-nota (PTV / Push-To-Video, o vídeo redondo curto). É um
    # vídeo — tratamos como tal pra não virar "[mensagem não suportada]".
    'ptvMessage' => :video,
    'audioMessage' => :audio,
    'documentMessage' => :file,
    'stickerMessage' => :image
  }.freeze

  # kind do endpoint /message/download/{kind} do Avisa por tipo de mensagem
  # whatsmeow — usado quando o webhook NÃO anexa o binário inline (figurinha e
  # áudio/voz SEMPRE; imagem/vídeo/documento às vezes). Sem isso, nota de voz e
  # afins caíam no fallback "[áudio recebido — não pôde ser processado]".
  DOWNLOAD_KINDS = {
    'imageMessage' => 'image',
    'videoMessage' => 'video',
    'ptvMessage' => 'video',  # PTV (vídeo-nota) baixa como vídeo no whatsmeow
    'audioMessage' => 'audio',
    'documentMessage' => 'document',
    'stickerMessage' => 'sticker'
  }.freeze

  def perform
    return if event.blank?
    unwrap_envelopes!
    return handle_reaction if reaction?
    return handle_edit if edit?
    return if protocol_noise?
    return if album_noise?
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

  # WhatsApp embrulha a mensagem REAL dentro de envelopes (mensagem temporária /
  # ver-uma-vez / documento-com-legenda). Sem desembrulhar, `extract_text` e a
  # detecção de mídia olham só as chaves de topo → caem em "[mensagem não
  # suportada]" (ex.: cliente com 'mensagens temporárias' ligado → TODO texto
  # dele viraria placeholder). Normaliza event['Message'] pro conteúdo interno
  # (recursivo: envelopes podem aninhar). Roda ANTES de reação/edição/persistência.
  ENVELOPE_KEYS = %w[
    ephemeralMessage viewOnceMessage viewOnceMessageV2
    viewOnceMessageV2Extension documentWithCaptionMessage
    deviceSentMessage associatedChildMessage
  ].freeze

  def unwrap_envelopes!
    msg = event['Message']
    return unless msg.is_a?(Hash)

    10.times do  # guard anti-loop; envelopes reais aninham 1-2 níveis
      key = ENVELOPE_KEYS.find { |k| msg[k].is_a?(Hash) }
      break unless key

      inner = msg[key]['message'] || msg[key]['Message']
      break unless inner.is_a?(Hash)

      msg = inner
    end
    event['Message'] = msg
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
    msg = event['Message'] || {}

    ext_text = msg.dig('extendedTextMessage', 'text')
    return ext_text if ext_text.present?

    return msg['conversation'] if msg['conversation'].present?

    # Resposta de botão/lista/flow (template/carrossel da Alice): a fala do
    # cliente É o rótulo escolhido. Sem isso, o tap no botão virava placeholder.
    reply = interactive_reply_text
    return reply if reply.present?

    # Template do WhatsApp (HSM): o corpo visível fica no `hydratedTemplate`
    # (título + conteúdo + rodapé). Sem isto, virava "[mensagem não suportada]".
    tpl = template_message_text
    return tpl if tpl.present?

    %w[imageMessage videoMessage documentMessage].each do |media_type|
      caption = msg.dig(media_type, 'caption')
      return caption if caption.present?
    end

    nil
  end

  # Texto visível de um `templateMessage` (Highly Structured Message). O corpo vem
  # no `hydratedTemplate`/`hydratedFourRowTemplate` (`hydratedContentText`), com
  # `hydratedTitle`/`hydratedFooterText` opcionais. Junta o que houver; nil se não
  # for template ou não tiver texto (cai no fluxo normal sem regressão).
  def template_message_text
    tpl = event.dig('Message', 'templateMessage')
    return nil unless tpl.is_a?(Hash)

    h = tpl['hydratedTemplate'] || tpl['hydratedFourRowTemplate'] ||
        tpl['fourRowTemplate']
    return nil unless h.is_a?(Hash)

    parts = [
      h['hydratedTitle'], h['hydratedContentText'], h['hydratedFooterText']
    ].compact.map(&:to_s).reject(&:empty?)
    parts.empty? ? nil : parts.join("\n")
  end

  # Texto da resposta interativa (botão simples, botão de template, item de lista,
  # flow nativo). Cada provider whatsmeow nomeia um pouco diferente — cobre todos.
  def interactive_reply_text
    msg = event['Message'] || {}
    msg.dig('buttonsResponseMessage', 'selectedDisplayText').presence ||
      msg.dig('templateButtonReplyMessage', 'selectedDisplayText').presence ||
      msg.dig('listResponseMessage', 'title').presence ||
      msg.dig('listResponseMessage', 'singleSelectReply', 'selectedRowId').presence ||
      msg.dig('interactiveResponseMessage', 'body', 'text').presence
  end

  # ID/payload do botão tocado (≠ do rótulo visível). No carrossel da Alice cada
  # card carrega `veiculo:<uuid>` no id do quick_reply; sem isto o attra-py não
  # sabe QUAL veículo o cliente escolheu (cai em handoff genérico). Espelha o
  # `button_payload: reply[:id]` do path Cloud (incoming_message_service_helpers),
  # que o serviço Avisa não tinha. Cobre os nomes whatsmeow de cada tipo.
  def interactive_reply_payload
    msg = event['Message'] || {}
    msg.dig('buttonsResponseMessage', 'selectedButtonId').presence ||
      msg.dig('templateButtonReplyMessage', 'selectedId').presence ||
      msg.dig('listResponseMessage', 'singleSelectReply', 'selectedRowId').presence ||
      msg.dig('interactiveResponseMessage', 'nativeFlowResponseMessage', 'paramsJson').presence
  end

  def reaction?
    event.dig('Message', 'reactionMessage').is_a?(Hash)
  end

  # protocolMessage que NÃO é edição (revoke/apagar, sync de chave de app, etc.) é
  # RUÍDO de sistema, não conteúdo do cliente. Se sobrar só ele (+ contextInfo),
  # ignora silenciosamente em vez de criar "[mensagem não suportada]".
  def protocol_noise?
    msg = event['Message'] || {}
    return false unless msg['protocolMessage'].is_a?(Hash)

    (msg.keys - %w[protocolMessage messageContextInfo]).empty?
  end

  # albumMessage é o "cabeçalho" de um álbum de mídia (metadados: expectedImageCount
  # / expectedVideoCount). As mídias REAIS chegam como mensagens SEPARADAS depois
  # (image/video), com contextInfo apontando pro álbum. Sozinho não tem conteúdo
  # exibível → ignora silenciosamente em vez de criar "[mensagem não suportada]"
  # (sintoma: conv recebia um placeholder no meio das fotos do álbum).
  def album_noise?
    msg = event['Message'] || {}
    return false unless msg['albumMessage'].is_a?(Hash)

    (msg.keys - %w[albumMessage messageContextInfo]).empty?
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

  # --- Resposta a STATUS (13/ago, conv 3769) --------------------------------
  # Quando o cliente responde a um STATUS da loja, o contextInfo traz o quote
  # de `status@broadcast` (e o whatsmeow marca entryPointConversionSource=
  # 'status') — e TAMBÉM re-anexa o externalAdReply da ORIGEM da thread (o
  # CTWA antigo que abriu a conversa). O assunto da mensagem é o STATUS
  # citado, não o anúncio velho: carimbar is_ad ali gravou "MERCEDES G-63
  # [2019]" numa pergunta sobre o Porsche Macan do Status.
  def status_reply?
    ctx = event.dig('Message', 'extendedTextMessage', 'contextInfo')
    return false unless ctx.is_a?(Hash)

    remote = first_present(ctx, 'remoteJID', 'remoteJid', 'RemoteJID').to_s
    source = first_present(ctx, 'entryPointConversionSource', 'EntryPointConversionSource').to_s
    remote == 'status@broadcast' || source == 'status'
  end

  # Legenda/texto do conteúdo CITADO (imagem/vídeo com caption, ou texto puro).
  def quoted_caption
    qm = event.dig('Message', 'extendedTextMessage', 'contextInfo', 'quotedMessage')
    return nil unless qm.is_a?(Hash)

    qm.dig('imageMessage', 'caption').presence ||
      qm.dig('videoMessage', 'caption').presence ||
      qm['conversation'].presence ||
      qm.dig('extendedTextMessage', 'text').presence
  end

  # --- Click-to-WhatsApp: anúncio patrocinado (Facebook/Instagram) -------------
  # Quando o cliente vem de um anúncio (CTWA), o WhatsApp anexa o anúncio em
  # extendedTextMessage.contextInfo.externalAdReply (título/corpo/sourceUrl/
  # mediaUrl/thumbnail). Antes o serviço lia só o `text` → a ORIGEM do lead era
  # descartada (sobrava só a fala do cliente). Aqui mapeamos pro mesmo formato
  # `content_attributes.ad_data` que o cria.chat usa, e o front desenha o card.
  def ad_reply
    ctx = event.dig('Message', 'extendedTextMessage', 'contextInfo')
    return nil unless ctx.is_a?(Hash)

    ad = ctx['externalAdReply'] || ctx['ExternalAdReply']
    ad.is_a?(Hash) ? ad : nil
  end

  def ad_data
    ad = ad_reply
    return nil if ad.nil?

    src_url = first_present(ad, 'sourceUrl', 'SourceUrl', 'sourceURL')
    media_url = first_present(ad, 'mediaUrl', 'MediaUrl', 'mediaURL')
    {
      'title' => first_present(ad, 'title', 'Title'),
      'body' => first_present(ad, 'body', 'Body'),
      'source_app' => ad_source_app(ad, src_url, media_url),
      'source_url' => src_url,
      'media_url' => media_url,
      'thumbnail_url' => first_present(ad, 'thumbnailUrl', 'ThumbnailUrl', 'thumbnailURL'),
      'thumbnail_data' => ad_thumbnail_b64(ad)
    }.reject { |_, v| v.blank? }.presence
  end

  # whatsmeow sourceType costuma ser genérico ('ad'); inferimos FB vs IG pela URL.
  def ad_source_app(ad, src_url, media_url)
    st = first_present(ad, 'sourceType', 'SourceType').to_s.downcase
    return st if %w[facebook instagram].include?(st)

    hay = "#{src_url} #{media_url}".downcase
    return 'instagram' if hay.include?('instagram') || hay.include?('ig.me')
    return 'facebook' if hay.match?(/facebook|fb\.me|fb\.com|fb\.watch/)

    st.presence
  end

  # thumbnail do anúncio: o JSON do whatsmeow serializa os bytes como base64
  # (string). Mantemos a string; o front renderiza `data:image/jpeg;base64,...`.
  def ad_thumbnail_b64(ad)
    raw = first_present(ad, 'thumbnail', 'Thumbnail', 'jpegThumbnail', 'JpegThumbnail')
    raw.is_a?(String) ? raw.presence : nil
  end

  def first_present(hash, *keys)
    keys.each do |k|
      v = hash[k]
      return v if v.present?
    end
    nil
  end

  # Cabeçalho compacto do anúncio (só usado quando o cliente NÃO mandou texto —
  # garante que a bolha do anúncio nunca fica vazia mesmo sem o card no front).
  def ad_header_text(data)
    app = data['source_app'].to_s.capitalize.presence
    rotulo = ['📢 Anúncio', app].compact.join(' - ')
    [rotulo, data['title'].presence, data['source_url'].presence].compact.join("\n\n")
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

  # Mídia recebida que não pôde ser baixada/processada vira texto-fallback por tipo,
  # pra bolha NUNCA ficar invisível (conversa sem mensagem = "nova mensagem" em branco).
  MEDIA_FALLBACK = {
    image: '[imagem recebida — não pôde ser processada]',
    video: '[vídeo recebido — não pôde ser processado]',
    audio: '[áudio recebido — não pôde ser processado]',
    file: '[documento recebido — não pôde ser processado]'
  }.freeze

  # Garante que toda conversa criada por um inbound também ganhe UMA mensagem visível.
  # Se a mídia falhar (tipo não suportado, arquivo ruim, exceção no attach), ainda
  # cria a mensagem com content de fallback + content_attributes['media_error'],
  # logando o erro em vez de descartar silenciosamente.
  def persist_message(conversation, contact)
    text = extract_text
    media = media_payload
    has_media = media_message_key.present?

    message = conversation.messages.build(message_attributes(text, contact))
    media_error = attach_media_safely(message, media) if has_media

    apply_content_fallback(message, text, has_media, media_error)
    message.save!
  end

  # Tenta anexar a mídia; nunca aborta a criação da mensagem. Retorna a razão da
  # falha (string) quando não consegue anexar, ou nil em sucesso.
  def attach_media_safely(message, media)
    return 'mídia presente mas binário ausente (inline e download falharam)' if media.blank?

    attach_media(message, media)
    nil
  rescue StandardError => e
    Rails.logger.error(
      "[AVISA] attach_media failed source_id=#{source_id} phone=#{phone_from_jid(resolved_jid)} " \
      "type=#{media_message_key} error=#{e.class}: #{e.message}"
    )
    "#{e.class}: #{e.message}"
  end

  # Decide o content/flags finais para que a bolha sempre renderize:
  #   - mídia que falhou -> fallback por tipo + media_error (com o motivo)
  #   - sem texto, sem mídia, sem anexo -> placeholder + unsupported=true
  def apply_content_fallback(message, text, has_media, media_error)
    return if message.attachments.present?

    if has_media
      message.content = text.presence || MEDIA_FALLBACK[media_file_type]
      message.content_attributes = message.content_attributes.merge('media_error' => media_error || 'mídia não processada')
      log_unprocessable('media') if text.blank?
    elsif text.blank?
      structured = describe_structured
      if structured.present?
        # Tipos estruturados (localização/contato/enquete/evento) viram resumo
        # VISÍVEL — o agente vê o que o cliente mandou em vez de "não suportada".
        message.content = structured
        message.content_attributes = message.content_attributes.merge(
          'structured_type' => message_type_keys.first,
        )
      else
        message.content = '[mensagem não suportada]'
        # Guarda as chaves do payload (ex.: ['pollUpdateMessage']) p/ diagnóstico
        # post-hoc — antes não dava pra saber QUE tipo caiu aqui.
        message.content_attributes = message.content_attributes.merge(
          'unsupported' => true,
          'unsupported_keys' => message_type_keys,
        )
        log_unprocessable('unsupported')
      end
    end
  end

  # Resumo VISÍVEL de tipos estruturados sem texto/mídia (localização, contato,
  # enquete, evento). Devolve nil quando não é um tipo conhecido → cai no
  # placeholder "[mensagem não suportada]" (com unsupported_keys p/ diagnóstico).
  def describe_structured
    msg = event['Message'] || {}

    if (loc = msg['locationMessage']).is_a?(Hash)
      lat = loc['degreesLatitude'] || loc['DegreesLatitude']
      lng = loc['degreesLongitude'] || loc['DegreesLongitude']
      rotulo = loc['name'].presence || loc['address'].presence
      maps = [lat, lng].all?(&:present?) ? "https://maps.google.com/?q=#{lat},#{lng}" : nil
      return ['[localização]', rotulo, maps].compact.join(' ')
    end
    return '[localização ao vivo compartilhada]' if msg['liveLocationMessage'].is_a?(Hash)

    if (c = msg['contactMessage']).is_a?(Hash)
      return "[contato] #{c['displayName']}".strip
    end
    if (ca = msg['contactsArrayMessage']).is_a?(Hash)
      return "[#{(ca['contacts'] || []).size} contato(s) compartilhado(s)]"
    end

    poll = msg['pollCreationMessage'] || msg['pollCreationMessageV2'] || msg['pollCreationMessageV3']
    if poll.is_a?(Hash)
      opts = (poll['options'] || []).map { |o| o['optionName'] }.compact
      resumo = "[enquete] #{poll['name']}"
      resumo += " — opções: #{opts.join(', ')}" if opts.any?
      return resumo.strip
    end

    if (ev = msg['eventMessage']).is_a?(Hash)
      return "[evento] #{ev['name']}".strip
    end

    nil
  end

  def media_file_type
    MEDIA_KEYS[media_message_key] || :file
  end

  # Chaves de tipo do payload já desembrulhado (sem ruído de contextInfo).
  def message_type_keys
    (event['Message'] || {}).keys - %w[messageContextInfo]
  end

  def log_unprocessable(kind)
    Rails.logger.error(
      "[AVISA] inbound sem conteúdo processável (#{kind}) — persistindo placeholder " \
      "source_id=#{source_id} phone=#{phone_from_jid(resolved_jid)} " \
      "tipos=#{message_type_keys.inspect}"
    )
  end

  def message_attributes(text, contact)
    outgoing = from_me?
    content_attrs = outgoing ? { external_echo: true } : {}
    content_attrs[:in_reply_to_external_id] = quoted_external_id if quoted_external_id.present?

    # Toque em botão/lista do carrossel: propaga o id do botão (`veiculo:<uuid>`)
    # + o rótulo, p/ o attra-py pré-selecionar o veículo (TRIGGER #15) em vez de
    # reinferir pelo texto "Quero Falar Sobre".
    button_payload = interactive_reply_payload
    if button_payload.present?
      content_attrs[:button_payload] = button_payload
      button_title = interactive_reply_text
      content_attrs[:button_title] = button_title if button_title.present?
    end

    # Anúncio CTWA (FB/IG): marca is_ad + ad_data p/ o front desenhar o card. Se o
    # cliente não mandou texto junto, usa o cabeçalho do anúncio como content pra
    # bolha não ficar vazia (e a origem aparecer mesmo sem o card).
    #
    # EXCEÇÃO — resposta a STATUS (13/ago, conv 3769): o externalAdReply que
    # acompanha o quote de status@broadcast é a origem ANTIGA da thread, não o
    # assunto. Preserva a legenda do Status citado (content_attributes
    # aditivos que o attra-py lê) e deixa o carimbo de anúncio de fora.
    if status_reply?
      content_attrs[:status_reply] = true
      quoted = quoted_caption
      content_attrs[:quoted_status_caption] = quoted if quoted.present?
    else
      ad = ad_data
      if ad.present?
        content_attrs[:is_ad] = true
        content_attrs[:ad_data] = ad
        text = ad_header_text(ad) if text.blank?
      end
    end

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
    msg = event['Message'] || {}
    MEDIA_KEYS.keys.find { |key| msg[key].is_a?(Hash) }
  end

  # Resolve a mídia como hash {io:, filename:, content_type:, file_type:}.
  # 1º o binário INLINE (params[:file], multipart do Avisa); se não vier inline
  # (figurinha/áudio SEMPRE; imagem/vídeo/doc às vezes), BAIXA o conteúdo
  # decriptado via /message/download/{kind}. nil → sem mídia ou download falhou
  # (caller cai no MEDIA_FALLBACK visível, sem regressão).
  def media_payload
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

    downloaded_media_attachment(key)
  end

  # Baixa imagem/vídeo/documento/figurinha decriptado do Avisa quando não veio inline.
  def downloaded_media_attachment(key)
    media = event.dig('Message', key) || {}
    bytes = avisa_client.download_media(kind: DOWNLOAD_KINDS[key], media_message: media)
    if bytes.blank?
      Rails.logger.warn("[AVISA] inbound #{key} source_id=#{source_id} download vazio — fallback")
      return nil
    end
    Rails.logger.info("[AVISA] inbound #{key} source_id=#{source_id} download OK (#{bytes.bytesize}B)")

    {
      io: StringIO.new(bytes),
      filename: downloaded_media_filename(key, media),
      content_type: downloaded_media_content_type(key, media),
      file_type: MEDIA_KEYS[key] || :file
    }
  end

  # Baixa o áudio (ptt/voice) decriptado — o webhook NUNCA anexa o áudio inline.
  # O anexo de áudio aciona a transcrição NATIVA do Chatwoot + player.
  def downloaded_audio_attachment
    audio = event.dig('Message', 'audioMessage') || {}
    bytes = avisa_client.download_audio(audio)
    if bytes.blank?
      Rails.logger.warn("[AVISA] audio inbound source_id=#{source_id} download vazio — fallback")
      return nil
    end
    Rails.logger.info("[AVISA] audio inbound source_id=#{source_id} download OK (#{bytes.bytesize}B)")

    {
      io: StringIO.new(bytes),
      filename: "audio-#{source_id.presence || 'voice'}.ogg",
      content_type: audio['mimetype'].to_s.split(';').first.presence || 'audio/ogg',
      file_type: :audio
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

  def document_filename
    event.dig('Message', 'documentMessage', 'fileName').to_s.presence
  end

  def attach_media(message, media)
    message.attachments.new(
      account_id: message.account_id,
      file_type: media[:file_type] || :file,
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
  # (NÃO substituir pela versão do fykos, que removeu este branch.)
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
