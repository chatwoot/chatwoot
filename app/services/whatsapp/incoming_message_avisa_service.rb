# CUSTOMIZAÇÃO_SYNAPSEOS
# Recebe payload cru da Avisa API (whatsmeow/Baileys format) direto, sem passar
# pelo N8N. O webhook entrega em application/x-www-form-urlencoded (texto) ou
# multipart/form-data (mídia) com os campos:
#   - token: token da instância (autentica channel)
#   - jsonData: string JSON com o evento completo
#   - file: binário já descriptografado (quando mídia)
#
# v1 cobre só texto (conversation, extendedTextMessage, captions). Mídia,
# reações, edições, grupos ficam pros PRs seguintes.
class Whatsapp::IncomingMessageAvisaService
  pattr_initialize [:inbox!, :params!]

  def perform
    return if event.blank?
    return if from_me?

    phone = phone_from_jid(resolved_jid)
    return if phone.blank?

    contact_inbox = ContactInboxWithContactBuilder.new(
      inbox: inbox,
      source_id: phone,
      contact_attributes: {
        name: event.dig('Info', 'PushName').presence || phone,
        phone_number: "+#{phone}"
      }
    ).perform

    conversation = find_or_create_conversation(contact_inbox)
    text = extract_text
    return if text.blank? # v1: descarta não-texto

    conversation.messages.create!(
      content: text,
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: :incoming,
      sender: contact_inbox.contact,
      source_id: event.dig('Info', 'ID').to_s
    )
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
