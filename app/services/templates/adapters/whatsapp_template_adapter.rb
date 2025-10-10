# frozen_string_literal: true

# Adapter to convert unified templates to WhatsApp format
# Handles WhatsApp's interactive messages, buttons, and lists
#
# Usage:
#   adapter = Templates::Adapters::WhatsappTemplateAdapter.new(
#     content_blocks: processed_blocks,
#     template: template,
#     parameters: { ... }
#   )
#   result = adapter.adapt
#
# Returns:
#   {
#     content_type: 'interactive',
#     content: 'Select an option',
#     content_attributes: { type: 'list', ... }
#   }
class Templates::Adapters::WhatsappTemplateAdapter
  attr_reader :content_blocks, :template, :parameters

  def initialize(content_blocks:, template:, parameters:)
    @content_blocks = content_blocks
    @template = template
    @parameters = parameters.with_indifferent_access
  end

  # Main entry point: adapt template to WhatsApp format
  def adapt
    channel_mapping = template.channel_mappings
                              &.find_by(channel_type: 'whatsapp')

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
    primary_block = @content_blocks.first
    return adapt_generic_content if primary_block.nil?

    case primary_block[:type]
    when 'time_picker', 'list_picker'
      adapt_interactive_message(primary_block)
    when 'payment_request'
      adapt_payment_message(primary_block)
    when 'quick_reply'
      adapt_quick_reply_message(primary_block)
    when 'button_group'
      adapt_button_message(primary_block)
    when 'media'
      adapt_media_message(primary_block)
    else
      adapt_generic_content
    end
  end

  def adapt_interactive_message(block)
    properties = block[:properties]
    block_type = block[:type]

    if block_type == 'list_picker'
      adapt_list_message(properties)
    else
      # Time picker as button-based selection
      adapt_button_based_time_picker(properties)
    end
  end

  def adapt_list_message(properties)
    # WhatsApp list message format
    sections = format_whatsapp_sections(properties['sections'])

    {
      content_type: 'interactive',
      content: properties['title'] || 'Select an option',
      content_attributes: {
        type: 'list',
        header: {
          type: 'text',
          text: properties['title'] || 'Select an option'
        },
        body: {
          text: properties['description'] || 'Please choose from the options below'
        },
        action: {
          button: properties['buttonText'] || 'View Options',
          sections: sections
        }
      }.compact
    }
  end

  def format_whatsapp_sections(sections)
    return [] unless sections.is_a?(Array)

    sections.map do |section|
      {
        title: section['title'],
        rows: format_whatsapp_rows(section['items'])
      }
    end
  end

  def format_whatsapp_rows(items)
    return [] unless items.is_a?(Array)

    items.take(10).map do |item| # WhatsApp limit: 10 rows per section
      {
        id: item['identifier'] || SecureRandom.uuid,
        title: item['title'] || 'Option',
        description: item['subtitle']
      }.compact
    end
  end

  def adapt_button_based_time_picker(properties)
    # Convert time slots to buttons (max 3 for WhatsApp)
    slots = properties['slots'] || []
    buttons = slots.take(3).map.with_index do |slot, index|
      time_str = format_time_for_display(slot)
      {
        type: 'reply',
        reply: {
          id: "slot_#{index}",
          title: time_str
        }
      }
    end

    {
      content_type: 'interactive',
      content: properties['title'] || 'Select a time',
      content_attributes: {
        type: 'button',
        body: {
          text: [properties['title'], properties['description']].compact.join("\n\n")
        },
        action: {
          buttons: buttons
        }
      }.compact
    }
  end

  def format_time_for_display(slot)
    time_str = slot.is_a?(Hash) ? slot['startTime'] : slot
    time = Time.zone.parse(time_str)
    time.strftime('%b %d, %I:%M %p')
  rescue ArgumentError
    slot.to_s.truncate(20) # WhatsApp button title limit
  end

  def adapt_payment_message(properties)
    # WhatsApp doesn't support native payments, convert to text with link
    amount = properties['amount']
    currency = properties['currencyCode'] || 'USD'
    merchant = properties['merchantName'] || 'Merchant'

    content = "💳 Payment Request\n\n"
    content += "Merchant: #{merchant}\n"
    content += "Amount: #{currency} #{amount}\n\n"

    if properties['lineItems']
      content += "Items:\n"
      properties['lineItems'].each do |item|
        content += "- #{item['label']}: #{currency} #{item['amount']}\n"
      end
    end

    content += "\nPlease proceed with payment."

    {
      content_type: 'text',
      content: content,
      content_attributes: {}
    }
  end

  def adapt_quick_reply_message(properties)
    # WhatsApp reply buttons (max 3)
    items = properties['items'] || []
    buttons = items.take(3).map do |item|
      {
        type: 'reply',
        reply: {
          id: item['identifier'] || SecureRandom.uuid,
          title: item['title']&.truncate(20) || 'Reply'
        }
      }
    end

    {
      content_type: 'interactive',
      content: properties['summaryText'] || 'Quick Reply',
      content_attributes: {
        type: 'button',
        body: {
          text: properties['summaryText'] || 'Please select an option'
        },
        action: {
          buttons: buttons
        }
      }.compact
    }
  end

  def adapt_button_message(properties)
    buttons = (properties['buttons'] || []).take(3).map do |button|
      {
        type: button['type'] == 'url' ? 'url' : 'reply',
        reply: if button['type'] == 'url'
                 nil
               else
                 {
                   id: button['identifier'] || SecureRandom.uuid,
                   title: button['title']&.truncate(20)
                 }
               end,
        url: button['type'] == 'url' ? button['url'] : nil
      }.compact
    end

    {
      content_type: 'interactive',
      content: properties['title'] || 'Select an option',
      content_attributes: {
        type: 'button',
        body: {
          text: [properties['title'], properties['description']].compact.join("\n\n")
        },
        action: {
          buttons: buttons
        }
      }.compact
    }
  end

  def adapt_media_message(properties)
    media_type = properties['mediaType'] || 'image'
    media_url = properties['url']

    {
      content_type: media_type,
      content: properties['caption'] || '',
      content_attributes: {
        url: media_url,
        caption: properties['caption']
      }.compact
    }
  end

  def adapt_generic_content
    # Combine all text blocks
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
    primary_block = @content_blocks.first
    return '' if primary_block.nil?

    primary_block.dig(:properties, 'title') ||
      primary_block.dig(:properties, 'content') ||
      primary_block.dig(:properties, 'summaryText') ||
      ''
  end

  def map_attributes(field_mappings)
    result = {}

    field_mappings.each do |target_path, source_path|
      value = extract_value_from_path(source_path)
      set_value_at_path(result, target_path, value) if value.present?
    end

    result
  end

  def extract_value_from_path(path)
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
