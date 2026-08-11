module Whatsapp::IncomingMessageServiceHelpers
  def download_attachment_file(attachment_payload)
    Down.download(inbox.channel.media_url(attachment_payload[:id]), headers: inbox.channel.api_headers)
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }.merge(ctwa_referral_attributes)
  end

  # CUSTOMIZAÇÃO_SYNAPSEOS: Click-to-WhatsApp — a Meta manda um bloco
  # `referral` na PRIMEIRA mensagem de quem clicou num anúncio (id do anúncio,
  # texto, url). O Chatwoot descartava esse dado, e sem ele não dá pra saber
  # de qual campanha o lead veio nem se ele veio de campanha de OUTRA marca
  # (2026-08-11: anúncio de Seguro Honda despejando lead no WhatsApp da Audi).
  # Guardamos na conversa pra ficar disponível ao bot e ao time.
  def ctwa_referral_attributes
    referral = messages_data&.first&.dig(:referral)
    return {} if referral.blank?

    { additional_attributes: { campaign: {
      source_type: referral[:source_type],
      source_id: referral[:source_id],
      source_url: referral[:source_url],
      headline: referral[:headline],
      body: referral[:body].to_s[0, 500],
      media_type: referral[:media_type],
      ctwa_clid: referral[:ctwa_clid]
    }.compact } }
  end

  def processed_params
    @processed_params ||= params
  end

  def account
    @account ||= inbox.account
  end

  def message_type
    messages_data.first[:type]
  end

  def message_content(message)
    # TODO: map interactive messages back to button messages in chatwoot
    message.dig(:text, :body) ||
      message.dig(:button, :text) ||
      message.dig(:interactive, :button_reply, :title) ||
      message.dig(:interactive, :list_reply, :title) ||
      message.dig(:name, :formatted_name)
  end

  def file_content_type(file_type)
    return :image if %w[image sticker].include?(file_type)
    return :audio if %w[audio voice].include?(file_type)
    return :video if ['video'].include?(file_type)
    return :location if ['location'].include?(file_type)
    return :contact if ['contacts'].include?(file_type)

    :file
  end

  def unprocessable_message_type?(message_type)
    %w[reaction ephemeral unsupported request_welcome].include?(message_type)
  end

  def processed_waid(waid)
    Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact_by_provider(waid, :cloud)
  end

  def error_webhook_event?(message)
    message.key?('errors')
  end

  def log_error(message)
    Rails.logger.warn "Whatsapp Error: #{message['errors'][0]['title']} - contact: #{message['from']}"
  end

  def process_in_reply_to(message)
    @in_reply_to_external_id = message['context']&.[]('id')
  end

  def find_message_by_source_id(source_id)
    return unless source_id

    @message = Message.find_by(source_id: source_id)
  end

  def lock_message_source_id!
    return false if messages_data.blank?

    Whatsapp::MessageDedupLock.new(messages_data.first[:id]).acquire!
  end
end
