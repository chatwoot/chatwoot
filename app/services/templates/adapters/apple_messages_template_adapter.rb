# frozen_string_literal: true

# Adapter to convert unified templates to Apple Messages for Business format
# Reuses existing AMB service logic for consistency
#
# Usage:
#   adapter = Templates::Adapters::AppleMessagesTemplateAdapter.new(
#     content_blocks: processed_blocks,
#     template: template,
#     parameters: { ... }
#   )
#   result = adapter.adapt
#
# Returns:
#   {
#     content_type: 'apple_time_picker',
#     content: 'Select a time',
#     content_attributes: { event: {...}, receivedMessage: {...} }
#   }
class Templates::Adapters::AppleMessagesTemplateAdapter
  attr_reader :content_blocks, :template, :parameters

  def initialize(content_blocks:, template:, parameters:)
    @content_blocks = content_blocks
    @template = template
    @parameters = parameters.with_indifferent_access
  end

  # Main entry point: adapt template to Apple Messages format
  def adapt
    channel_mapping = template.channel_mappings
                              &.find_by(channel_type: 'apple_messages_for_business')

    if channel_mapping
      adapt_with_mapping(channel_mapping)
    else
      adapt_with_defaults
    end
  end

  private

  def adapt_with_mapping(mapping)
    {
      content_type: mapping.content_type,
      content: generate_content,
      content_attributes: map_attributes(mapping.field_mappings)
    }
  end

  def adapt_with_defaults
    # Default adaptation logic for Apple Messages
    primary_block = @content_blocks.first
    return adapt_generic_content if primary_block.nil?

    case primary_block[:type]
    when 'time_picker'
      adapt_time_picker(primary_block)
    when 'list_picker'
      adapt_list_picker(primary_block)
    when 'payment_request'
      adapt_payment_request(primary_block)
    when 'form'
      adapt_form(primary_block)
    when 'quick_reply'
      adapt_quick_reply(primary_block)
    when 'rich_link'
      adapt_rich_link(primary_block)
    when 'imessage_app'
      adapt_imessage_app(primary_block)
    when 'auth_request', 'oauth'
      adapt_oauth(primary_block)
    else
      adapt_generic_content
    end
  end

  def adapt_time_picker(block)
    properties = block[:properties]

    # CRITICAL: Use camelCase for imageIdentifier (frontend sends camelCase)
    # Check both camelCase and snake_case for compatibility
    event_image_id = properties['imageIdentifier'] || properties['image_identifier']
    received_image_id = properties['receivedImageIdentifier'] || properties['received_image_identifier']
    reply_image_id = properties['replyImageIdentifier'] || properties['reply_image_identifier']

    # If reply image not specified, reuse received image (Apple MSP best practice)
    reply_image_id = received_image_id if reply_image_id.blank?

    {
      content_type: 'apple_time_picker',
      content: properties['title'] || 'Select a time',
      content_attributes: {
        event: {
          title: properties['title'],
          description: properties['description'],
          identifier: properties['identifier'] || SecureRandom.uuid,
          timeslots: format_timeslots(properties['slots']),
          timezoneOffset: properties['timezoneOffset'] || properties['timezone_offset'],
          imageIdentifier: event_image_id
        }.compact,
        received_title: properties['receivedTitle'] || properties['received_title'] || properties['title'],
        reply_title: properties['replyTitle'] || properties['reply_title'] || 'Selected: ${event.title}',
        receivedImageIdentifier: received_image_id,
        replyImageIdentifier: reply_image_id,
        received_style: properties['receivedStyle'] || properties['received_style'] || 'large',
        reply_style: properties['replyStyle'] || properties['reply_style'] || 'large',
        images: properties['images'] || []
      }.compact
    }
  end

  def format_timeslots(slots)
    return [] unless slots.is_a?(Array)

    slots.map.with_index do |slot_time, index|
      # Handle both string timestamps and hash objects
      if slot_time.is_a?(Hash)
        {
          identifier: slot_time['identifier'] || "slot_#{index}",
          startTime: format_time(slot_time['startTime']),
          duration: slot_time['duration'] || 3600
        }
      else
        {
          identifier: "slot_#{index}",
          startTime: format_time(slot_time),
          duration: @template.parameters.dig('appointment_duration', 'default') || 3600
        }
      end
    end
  end

  def format_time(time_input)
    return nil unless time_input

    time = case time_input
           when String
             Time.zone.parse(time_input)
           when Integer
             Time.zone.at(time_input)
           when Time, DateTime
             time_input
           else
             return time_input.to_s
           end

    # Apple MSP format: 2017-05-26T08:27+0000
    time.utc.strftime('%Y-%m-%dT%H:%M+0000')
  rescue ArgumentError
    time_input.to_s
  end

  def adapt_list_picker(block)
    properties = block[:properties]

    # CRITICAL: Check both camelCase and snake_case for imageIdentifier
    received_image_id = properties['receivedImageIdentifier'] || properties['received_image_identifier']
    reply_image_id = properties['replyImageIdentifier'] || properties['reply_image_identifier']

    {
      content_type: 'apple_list_picker',
      content: properties['title'] || 'Select an option',
      content_attributes: {
        sections: format_list_picker_sections(properties['sections']),
        received_title: properties['receivedTitle'] || properties['received_title'] || properties['title'],
        reply_title: properties['replyTitle'] || properties['reply_title'] || 'Selected: ${item.title}',
        receivedImageIdentifier: received_image_id,
        replyImageIdentifier: reply_image_id,
        received_style: properties['receivedStyle'] || properties['received_style'] || 'small',
        reply_style: properties['replyStyle'] || properties['reply_style'] || 'icon',
        images: properties['images'] || []
      }.compact
    }
  end

  def format_list_picker_sections(sections)
    return [] unless sections.is_a?(Array)

    sections.map.with_index do |section, section_index|
      {
        'title' => section['title'] || "Section #{section_index + 1}",
        'multipleSelection' => section['multipleSelection'] || false,
        'order' => section['order'] || section_index,
        'items' => format_list_picker_items(section['items'], section_index)
      }
    end
  end

  def format_list_picker_items(items, _section_index)
    return [] unless items.is_a?(Array)

    items.map.with_index do |item, item_index|
      # CRITICAL: Check both camelCase and snake_case for imageIdentifier
      # Frontend sends camelCase, but accept both for compatibility
      image_id = item['imageIdentifier'] || item['image_identifier']

      {
        'identifier' => item['identifier'] || SecureRandom.uuid,
        'title' => item['title'] || "Item #{item_index + 1}",
        'subtitle' => item['subtitle'],
        'imageIdentifier' => image_id, # Always output as camelCase for Apple MSP
        'order' => item['order'] || item_index,
        'style' => item['style'] || 'icon'
      }.compact
    end
  end

  def adapt_payment_request(block)
    properties = block[:properties]

    {
      content_type: 'apple_pay',
      content: properties['title'] || 'Payment Request',
      content_attributes: {
        payment: {
          merchantIdentifier: properties['merchantIdentifier'],
          merchantName: properties['merchantName'],
          countryCode: properties['countryCode'] || 'US',
          currencyCode: properties['currencyCode'] || 'USD',
          paymentNetworks: properties['paymentNetworks'] || %w[visa mastercard amex],
          lineItems: properties['lineItems'] || [],
          total: {
            label: properties['totalLabel'] || 'Total',
            amount: properties['amount'],
            type: properties['totalType'] || 'final'
          }
        },
        receivedTitle: properties['receivedTitle'] || properties['title'],
        replyTitle: properties['replyTitle'] || 'Payment Sent',
        images: properties['images'] || []
      }.compact
    }
  end

  def adapt_form(block)
    properties = block[:properties]

    # Build received_message with both camelCase and snake_case support
    received_msg = properties['receivedMessage'] || properties['received_message'] || {}
    received_image_id = received_msg['imageIdentifier'] || received_msg['image_identifier']

    # Build reply_message with both camelCase and snake_case support
    reply_msg = properties['replyMessage'] || properties['reply_message'] || {}
    reply_image_id = reply_msg['imageIdentifier'] || reply_msg['image_identifier']

    # If reply image not specified, reuse received image (Apple MSP best practice)
    reply_image_id = received_image_id if reply_image_id.blank?

    {
      content_type: 'apple_form',
      content: properties['title'] || 'Please fill out this form',
      content_attributes: {
        title: properties['title'],
        description: properties['description'],
        pages: properties['pages'] || [],
        show_summary: properties['showSummary'] || properties['show_summary'] || false,
        received_message: {
          title: received_msg['title'] || properties['title'],
          subtitle: received_msg['subtitle'],
          imageIdentifier: received_image_id,
          style: received_msg['style'] || 'large'
        }.compact,
        reply_message: {
          title: reply_msg['title'] || 'Thank you for your submission!',
          subtitle: reply_msg['subtitle'],
          imageIdentifier: reply_image_id,
          style: reply_msg['style'] || 'large'
        }.compact,
        images: properties['images'] || []
      }.compact
    }
  end

  def adapt_quick_reply(block)
    properties = block[:properties]

    {
      content_type: 'apple_quick_reply',
      content: properties['summaryText'] || 'Quick Reply',
      content_attributes: {
        summaryText: properties['summaryText'],
        items: properties['items'] || [],
        images: properties['images'] || []
      }.compact
    }
  end

  def adapt_rich_link(block)
    properties = block[:properties]

    {
      content_type: 'apple_rich_link',
      content: properties['title'] || 'Rich Link',
      content_attributes: {
        url: properties['url'],
        title: properties['title'],
        subtitle: properties['subtitle'],
        imageUrl: properties['imageUrl'],
        openInSafari: properties['openInSafari'] || false
      }.compact
    }
  end

  def adapt_imessage_app(block)
    properties = block[:properties]

    # iMessage App interactive message
    # See: https://developer.apple.com/documentation/businesschatapi/messages_sent/interactive_messages/imessage_apps
    {
      content_type: 'apple_imessage_app',
      content: properties['title'] || 'iMessage App',
      content_attributes: {
        appId: properties['appId'] || properties['app_id'],
        appName: properties['appName'] || properties['app_name'],
        url: properties['url'], # URL scheme to launch the app
        useLiveLayout: properties['useLiveLayout'] || properties['use_live_layout'] || false,
        receivedMessage: {
          title: properties['receivedTitle'] || properties['received_title'] || properties['title'],
          subtitle: properties['receivedSubtitle'] || properties['received_subtitle'],
          imageUrl: properties['receivedImageUrl'] || properties['received_image_url'],
          imageIdentifier: properties['receivedImageIdentifier'] || properties['received_image_identifier'],
          style: properties['receivedStyle'] || properties['received_style'] || 'icon'
        }.compact,
        replyMessage: {
          title: properties['replyTitle'] || properties['reply_title'] || 'Message from ${app.name}',
          subtitle: properties['replySubtitle'] || properties['reply_subtitle'],
          imageUrl: properties['replyImageUrl'] || properties['reply_image_url'],
          imageIdentifier: properties['replyImageIdentifier'] || properties['reply_image_identifier'],
          style: properties['replyStyle'] || properties['reply_style'] || 'icon'
        }.compact,
        data: properties['data'] || {}, # Custom data passed to the app
        images: properties['images'] || []
      }.compact
    }
  end

  def adapt_oauth(block)
    properties = block[:properties]

    # OAuth authentication request
    # See: https://developer.apple.com/documentation/businesschatapi/messages_sent/interactive_messages/authentication
    {
      content_type: 'apple_auth',
      content: properties['title'] || 'Authentication Required',
      content_attributes: {
        oauth2: {
          responseType: properties['responseType'] || properties['response_type'] || 'code',
          scope: properties['scope'] || [],
          state: properties['state'] || SecureRandom.uuid,
          responseEncryptionKey: properties['responseEncryptionKey'] || properties['response_encryption_key']
        }.compact,
        receivedMessage: {
          title: properties['receivedTitle'] || properties['received_title'] || 'Please authenticate',
          subtitle: properties['receivedSubtitle'] || properties['received_subtitle'],
          imageIdentifier: properties['receivedImageIdentifier'] || properties['received_image_identifier'],
          style: properties['receivedStyle'] || properties['received_style'] || 'icon'
        }.compact,
        replyMessage: {
          title: properties['replyTitle'] || properties['reply_title'] || 'Authentication complete',
          subtitle: properties['replySubtitle'] || properties['reply_subtitle'],
          imageIdentifier: properties['replyImageIdentifier'] || properties['reply_image_identifier'],
          style: properties['replyStyle'] || properties['reply_style'] || 'icon'
        }.compact,
        images: properties['images'] || []
      }.compact
    }
  end

  def adapt_generic_content
    # Combine all text blocks into simple text message
    text_content = @content_blocks
                   .select { |block| block[:type] == 'text' }
                   .filter_map { |block| block.dig(:properties, 'content') }
                   .join("\n\n")

    {
      content_type: 'text',
      content: text_content.presence || 'Message',
      content_attributes: {}
    }
  end

  def generate_content
    # Extract primary content from first block
    primary_block = @content_blocks.first
    return '' if primary_block.nil?

    primary_block.dig(:properties, 'title') ||
      primary_block.dig(:properties, 'content') ||
      primary_block.dig(:properties, 'summaryText') ||
      ''
  end

  def map_attributes(field_mappings)
    # Apply custom field mappings from template
    result = {}

    field_mappings.each do |target_path, source_path|
      value = extract_value_from_path(source_path)
      set_value_at_path(result, target_path, value) if value.present?
    end

    result
  end

  def extract_value_from_path(path)
    # Extract value from path like "{{parameters.title}}" or "{{blocks.0.properties.title}}"
    return path unless path.is_a?(String) && path.include?('{{')

    path.scan(/\{\{([^}]+)\}\}/).flatten.first&.then do |variable_path|
      navigate_path(variable_path)
    end
  end

  def navigate_path(path)
    parts = path.split('.')
    current = { 'blocks' => @content_blocks, 'template' => @template }

    parts.each do |part|
      current = if /^\d+$/.match?(part)
                  current[part.to_i]
                else
                  current[part] || current[part.to_sym]
                end

      return nil if current.nil?
    end

    current
  end

  def set_value_at_path(hash, path, value)
    parts = path.split('.')
    last_key = parts.pop

    parts.each do |part|
      hash[part] ||= {}
      hash = hash[part]
    end

    hash[last_key] = value
  end
end
