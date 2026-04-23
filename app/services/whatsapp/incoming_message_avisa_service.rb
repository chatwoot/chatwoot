# CUSTOMIZAÇÃO_SYNAPSEOS
# Recebe payload cru da Avisa API (whatsmeow/Baileys format) direto, sem passar
# pelo N8N. O webhook entrega em application/x-www-form-urlencoded (texto) ou
# multipart/form-data (mídia) com os campos:
#   - token: token da instância (autentica channel)
#   - jsonData: string JSON com o evento completo
#   - file: binário já descriptografado (quando mídia)
#
# Cobre texto (conversation, extendedTextMessage) e mídia (image, audio, video,
# document) com caption opcional. Eventos com IsFromMe=true são persistidos
# como :outgoing (echo do celular do atendente) com dedup por source_id —
# mensagens originadas no próprio Chatwoot já têm source_id gravado pelo
# SendOnWhatsappService, então o echo da Avisa não duplica. Reações, edições
# e grupos ainda pendentes.
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
    return if source_id.present? && Message.exists?(source_id: source_id, inbox_id: inbox.id)

    phone = phone_from_jid(resolved_jid)
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

  def extract_text
    msg = event['Message'] || {}

    edited = msg.dig('protocolMessage', 'editedMessage') || {}
    return edited['conversation'] if edited['conversation'].present?
    return edited.dig('extendedTextMessage', 'text') if edited.dig('extendedTextMessage', 'text').present?

    ext_text = msg.dig('extendedTextMessage', 'text')
    return ext_text if ext_text.present?

    return msg['conversation'] if msg['conversation'].present?

    %w[imageMessage videoMessage documentMessage].each do |media_type|
      caption = msg.dig(media_type, 'caption')
      return caption if caption.present?
    end

    nil
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
    {
      content: text,
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: outgoing ? :outgoing : :incoming,
      status: outgoing ? :delivered : :sent,
      sender: outgoing ? nil : contact,
      source_id: source_id,
      content_attributes: outgoing ? { external_echo: true } : {}
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

  def find_or_create_conversation(contact_inbox)
    conversation = contact_inbox.conversations
                                .where(status: %w[open pending snoozed])
                                .order(created_at: :desc)
                                .first
    return conversation if conversation

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
