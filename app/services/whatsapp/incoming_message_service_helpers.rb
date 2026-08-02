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
    message.dig(:text, :body) ||
      message.dig(:button, :text) ||
      message.dig(:interactive, :button_reply, :title) ||
      message.dig(:interactive, :list_reply, :title) ||
      message.dig(:name, :formatted_name)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def interactive_reply_attributes(message)
    button_reply = message.dig(:interactive, :button_reply)
    list_reply = message.dig(:interactive, :list_reply)
    button = message[:button] || message['button']

    if button.present?
      selected_reply = {
        id: button[:payload] || button['payload'],
        title: button[:text] || button['text'],
        type: 'button'
      }

      selected_reply.merge!(button_reply_context(selected_reply[:id]))

      return {
        selected_reply: selected_reply.compact
      }
    end

    reply = button_reply || list_reply
    return {} if reply.blank?

    selected_reply = {
      id: reply[:id] || reply['id'],
      title: reply[:title] || reply['title'],
      type: button_reply.present? ? 'button_reply' : 'list_reply'
    }

    selected_reply.merge!(interactive_buttons_reply_context(reply)) if button_reply.present?
    selected_reply.merge!(interactive_list_reply_context(reply)) if list_reply.present?

    {
      selected_reply: selected_reply.compact
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  def file_content_type(file_type)
    return :image if %w[image sticker].include?(file_type)
    return :audio if %w[audio voice].include?(file_type)
    return :video if ['video'].include?(file_type)
    return :location if ['location'].include?(file_type)
    return :contact if ['contacts'].include?(file_type)

    :file
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

    @in_reply_to_message_id = Whatsapp::InReplyToMessageFinder.new(
      conversation: @conversation,
      source_id: @in_reply_to_external_id
    ).perform&.id
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

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def interactive_list_reply_context(reply)
    source = source_message
    section, row = interactive_list_source_row(source, reply[:id] || reply['id'])

    {
      description: (reply[:description] || reply['description'] || row&.dig('description') || row&.dig(:description)),
      section_title: section&.dig('title') || section&.dig(:title),
      source_message_external_id: @in_reply_to_external_id,
      source_message_id: source&.id,
      source_message_content_type: source&.content_type
    }
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def interactive_buttons_reply_context(reply)
    button_id = reply[:id] || reply['id']
    source_button_index, _source_button = interactive_buttons_source_button(source_message, button_id)

    {
      source_message_external_id: @in_reply_to_external_id,
      source_message_id: source_message&.id,
      source_message_content_type: source_message&.content_type,
      button_index: source_button_index
    }
  end

  def button_reply_context(reply_id)
    card_index, card, _action = carousel_source_action(source_message, reply_id)

    {
      source_message_external_id: @in_reply_to_external_id,
      source_message_id: source_message&.id,
      source_message_content_type: source_message&.content_type,
      card_index: card_index,
      card_title: card&.dig('title') || card&.dig(:title),
      card_description: card&.dig('description') || card&.dig(:description)
    }
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def interactive_buttons_source_button(source_message, button_id)
    return [nil, nil] if source_message.blank? || button_id.blank? || source_message.content_type != 'interactive_buttons'

    buttons = source_message.content_attributes['buttons'] || source_message.content_attributes[:buttons]

    Array(buttons).each_with_index do |button, index|
      next unless (button['id'] || button[:id]) == button_id

      return [index, button]
    end

    [nil, nil]
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def carousel_source_action(source_message, reply_id)
    return [nil, nil, nil] if source_message.blank? || reply_id.blank? || source_message.content_type != 'cards'

    items = source_message.content_attributes['items'] || source_message.content_attributes[:items]

    Array(items).each_with_index do |card, index|
      actions = Array(card['actions'] || card[:actions])
      action = actions.find { |candidate| (candidate['payload'] || candidate[:payload]) == reply_id }
      return [index, card, action] if action.present?
    end

    [nil, nil, nil]
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  # rubocop:disable Metrics/CyclomaticComplexity
  def interactive_list_source_row(source_message, reply_id)
    return [nil, nil] if source_message.blank? || reply_id.blank?

    Array(source_message.content_attributes['sections']).each do |section|
      rows = Array(section['rows'] || section[:rows])
      row = rows.find { |candidate| (candidate['id'] || candidate[:id]) == reply_id }
      return [section, row] if row.present?
    end

    [nil, nil]
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def source_message
    @source_message ||= Message.find_by(source_id: @in_reply_to_external_id)
  end
end
# rubocop:enable Metrics/ModuleLength
