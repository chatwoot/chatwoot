# rubocop:disable Metrics/ModuleLength
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
    }
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
    return I18n.t('conversations.messages.whatsapp.flow_response') if message.dig(:interactive, :nfm_reply).present?

    # TODO: map interactive messages back to button messages in chatwoot
    message.dig(:text, :body) ||
      message.dig(:button, :text) ||
      message.dig(:interactive, :button_reply, :title) ||
      message.dig(:interactive, :list_reply, :title) ||
      message.dig(:name, :formatted_name)
  end

  def parse_flow_response_json(response_json)
    parsed_response = JSON.parse(response_json)
    parsed_response.is_a?(Hash) ? parsed_response : response_json
  rescue JSON::ParserError, TypeError
    response_json
  end

  def file_content_type(file_type)
    return :image if %w[image sticker].include?(file_type)
    return :audio if %w[audio voice].include?(file_type)
    return :video if ['video'].include?(file_type)
    return :location if ['location'].include?(file_type)
    return :contact if ['contacts'].include?(file_type)

    :file
  end

  def normalize_ogg_audio_content_type(attachment, attachment_payload)
    return unless attachment_payload[:mime_type]&.start_with?('audio/ogg')
    return unless attachment.file.blob.content_type == 'audio/opus'

    attachment.file.blob.update!(content_type: 'audio/ogg')
  end

  def unprocessable_message_type?(message_type)
    %w[reaction ephemeral request_welcome].include?(message_type)
  end

  def processed_waid(waid)
    Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact_by_provider(waid, :cloud)
  end

  def whatsapp_phone_number(identifier)
    identifier = identifier.to_s
    return if identifier.blank?
    return unless identifier.match?(/\A\d{1,15}\z/)

    identifier
  end

  def error_webhook_event?(message)
    message.key?('errors')
  end

  def log_error(message)
    Rails.logger.warn "Whatsapp Error: #{message['errors'][0]['title']} - contact: #{message['from']}"
  end

  def process_in_reply_to(message)
    @in_reply_to_external_id = message['context']&.[]('id')
    return if @in_reply_to_external_id.blank?

    @in_reply_to_message = Whatsapp::InReplyToMessageFinder.new(
      conversation: @conversation,
      source_id: @in_reply_to_external_id
    ).perform
    @in_reply_to_message_id = @in_reply_to_message&.id
  end

  def whatsapp_interactive_reply_attributes(message)
    interactive = message[:interactive]
    reply_type = interactive&.[](:type)
    return if %w[button_reply list_reply].exclude?(reply_type)

    provider_reply = interactive[reply_type]
    return unless provider_reply.is_a?(Hash)

    {
      type: reply_type,
      delivery_id: provider_reply[:id],
      title: provider_reply[:title],
      description: provider_reply[:description],
      context_id: message.dig(:context, :id),
      originating_message_id: @in_reply_to_message_id
    }.compact.merge(whatsapp_interactive_reply_snapshot_match(reply_type, provider_reply[:id]))
  end

  def whatsapp_interactive_reply_content_attributes(message)
    reply = whatsapp_interactive_reply_attributes(message)
    reply.present? ? { whatsapp_interactive_reply: reply } : {}
  end

  def whatsapp_interactive_reply_snapshot_match(reply_type, delivery_id)
    return {} if delivery_id.blank?

    snapshot = trusted_whatsapp_interactive_snapshot
    return {} unless snapshot

    option, card_index = whatsapp_interactive_snapshot_options(snapshot, reply_type).find do |candidate, _index|
      candidate['delivery_id'] == delivery_id
    end
    return {} unless option

    { preset_option_id: option['preset_option_id'], card_index: card_index }.compact
  end

  def trusted_whatsapp_interactive_snapshot
    return unless @in_reply_to_message&.outgoing?

    snapshot = @in_reply_to_message.content_attributes['whatsapp_interactive']
    snapshot if snapshot.is_a?(Hash) && snapshot['schema_version'] == Whatsapp::InteractiveMessages::Registry::SCHEMA_VERSION
  end

  def whatsapp_interactive_snapshot_options(snapshot, reply_type)
    case "#{snapshot['type']}:#{reply_type}"
    when 'button:button_reply'
      Array(snapshot.dig('action', 'buttons')).map { |button| [button, nil] }
    when 'list:list_reply'
      Array(snapshot.dig('action', 'sections')).flat_map do |section|
        Array(section['rows']).map { |row| [row, nil] }
      end
    when 'carousel:button_reply'
      whatsapp_carousel_reply_options(snapshot)
    else
      []
    end
  end

  def whatsapp_carousel_reply_options(snapshot)
    Array(snapshot.dig('action', 'cards')).select { |card| card['type'] == 'button' }.flat_map do |card|
      Array(card.dig('action', 'buttons')).map { |button| [button, card['card_index']] }
    end
  end

  def referral_attributes(message)
    return {} if outgoing_echo

    message[:referral]&.to_h&.deep_stringify_keys || {}
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
# rubocop:enable Metrics/ModuleLength
