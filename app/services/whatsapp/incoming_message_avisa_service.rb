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
    msg = event['Message'] || {}

    ext_text = msg.dig('extendedTextMessage', 'text')
    return ext_text if ext_text.present?

    return msg['conversation'] if msg['conversation'].present?

    %w[imageMessage videoMessage documentMessage].each do |media_type|
      caption = msg.dig(media_type, 'caption')
      return caption if caption.present?
    end

    nil
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
    file = media_upload
    return if text.blank? && file.blank?

    message = conversation.messages.build(message_attributes(text, contact))
    attach_media(message, file) if file.present?
    message.save!
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
    msg = event['Message'] || {}
    MEDIA_KEYS.keys.find { |key| msg[key].is_a?(Hash) }
  end

  def media_upload
    return nil if media_message_key.blank?

    file = params[:file]
    return nil if file.blank?
    return nil unless file.respond_to?(:original_filename) && file.respond_to?(:content_type)

    file
  end

  def attach_media(message, file)
    key = media_message_key
    file_type = MEDIA_KEYS[key] || :file
    msg = event['Message'] || {}
    doc_name = msg.dig('documentMessage', 'fileName').to_s.presence

    message.attachments.new(
      account_id: message.account_id,
      file_type: file_type,
      file: {
        io: file.tempfile,
        filename: doc_name || file.original_filename,
        content_type: file.content_type
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
