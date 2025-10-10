# frozen_string_literal: true

# Adapter to convert unified templates to Web Widget format
# Handles web widget forms, buttons, and rich content
#
# Usage:
#   adapter = Templates::Adapters::WebWidgetTemplateAdapter.new(
#     content_blocks: processed_blocks,
#     template: template,
#     parameters: { ... }
#   )
#   result = adapter.adapt
#
# Returns:
#   {
#     content_type: 'form',
#     content: 'Fill out this form',
#     content_attributes: { fields: [...] }
#   }
class Templates::Adapters::WebWidgetTemplateAdapter
  attr_reader :content_blocks, :template, :parameters

  def initialize(content_blocks:, template:, parameters:)
    @content_blocks = content_blocks
    @template = template
    @parameters = parameters.with_indifferent_access
  end

  # Main entry point: adapt template to Web Widget format
  def adapt
    channel_mapping = template.channel_mappings
                              &.find_by(channel_type: 'web_widget')

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
    primary_block = content_blocks.first
    return adapt_generic_content if primary_block.nil?

    case primary_block[:type]
    when 'time_picker'
      adapt_time_picker(primary_block)
    when 'list_picker'
      adapt_list_picker(primary_block)
    when 'form'
      adapt_form(primary_block)
    when 'quick_reply', 'button_group'
      adapt_buttons(primary_block)
    when 'payment_request'
      adapt_payment(primary_block)
    else
      adapt_generic_content
    end
  end

  def adapt_time_picker(block)
    properties = block[:properties]
    slots = properties['slots'] || []

    # Convert time slots to dropdown options
    options = slots.map.with_index do |slot, index|
      time_str = format_time_for_display(slot)
      {
        label: time_str,
        value: slot.is_a?(Hash) ? slot['identifier'] : "slot_#{index}"
      }
    end

    {
      content_type: 'form',
      content: properties['title'] || 'Select a time',
      content_attributes: {
        title: properties['title'],
        description: properties['description'],
        fields: [
          {
            type: 'select',
            name: 'selected_time',
            label: properties['title'] || 'Select a time',
            options: options,
            required: true
          }
        ]
      }.compact
    }
  end

  def format_time_for_display(slot)
    time_str = slot.is_a?(Hash) ? slot['startTime'] : slot
    time = Time.zone.parse(time_str.to_s)
    time.strftime('%B %d, %Y at %I:%M %p')
  rescue ArgumentError
    slot.to_s
  end

  def adapt_list_picker(block)
    properties = block[:properties]
    sections = properties['sections'] || []

    # Flatten sections into single list for web widget
    all_items = sections.flat_map do |section|
      (section['items'] || []).map do |item|
        {
          label: "#{section['title']}: #{item['title']}",
          value: item['identifier'] || SecureRandom.uuid,
          description: item['subtitle']
        }
      end
    end

    # Determine if multiple selection based on first section
    multiple_selection = sections.first&.dig('multipleSelection') || false
    field_type = multiple_selection ? 'checkbox' : 'radio'

    {
      content_type: 'form',
      content: properties['title'] || 'Select an option',
      content_attributes: {
        title: properties['title'],
        description: properties['description'],
        fields: [
          {
            type: field_type,
            name: 'selected_items',
            label: properties['title'] || 'Select an option',
            options: all_items,
            required: true
          }
        ]
      }.compact
    }
  end

  def adapt_form(block)
    properties = block[:properties]
    pages = properties['pages'] || []

    # Flatten all pages into single form for web widget
    fields = pages.flat_map do |page|
      (page['items'] || []).map { |item| convert_form_item_to_field(item) }
    end.compact

    {
      content_type: 'form',
      content: properties['title'] || 'Please fill out this form',
      content_attributes: {
        title: properties['title'],
        description: properties['description'],
        fields: fields,
        submit_button: properties['submit_button'] || { text: 'Submit' },
        cancel_button: properties['cancel_button'] || { text: 'Cancel' }
      }.compact
    }
  end

  def convert_form_item_to_field(item)
    base_field = {
      type: map_item_type_to_field_type(item['item_type']),
      name: item['item_id'],
      label: item['title'],
      placeholder: item['placeholder'],
      description: item['description'],
      required: item['required'] || false
    }.compact

    # Add type-specific attributes
    case item['item_type']
    when 'text', 'textArea', 'email', 'phone'
      base_field[:max_length] = item['max_length'] if item['max_length']
      base_field[:input_type] = item['keyboard_type'] if item['keyboard_type']
    when 'singleSelect', 'multiSelect'
      base_field[:options] = item['options']&.map do |opt|
        { label: opt['title'], value: opt['value'] }
      end
    when 'dateTime'
      base_field[:min_date] = item['min_date'] if item['min_date']
      base_field[:max_date] = item['max_date'] if item['max_date']
    when 'stepper'
      base_field[:min_value] = item['min_value']
      base_field[:max_value] = item['max_value']
      base_field[:step] = item['step'] || 1
    end

    base_field
  end

  def map_item_type_to_field_type(item_type)
    case item_type
    when 'text' then 'text'
    when 'textArea' then 'textarea'
    when 'email' then 'email'
    when 'phone' then 'tel'
    when 'singleSelect' then 'select'
    when 'multiSelect' then 'checkbox'
    when 'dateTime' then 'datetime-local'
    when 'toggle' then 'checkbox'
    when 'stepper' then 'number'
    else 'text'
    end
  end

  def adapt_buttons(block)
    properties = block[:properties]
    buttons = if block[:type] == 'quick_reply'
                properties['items'] || []
              else
                properties['buttons'] || []
              end

    {
      content_type: 'input_select',
      content: properties['title'] || properties['summaryText'] || 'Select an option',
      content_attributes: {
        items: buttons.map do |button|
          {
            title: button['title'],
            value: button['identifier'] || button['value'] || SecureRandom.uuid
          }
        end
      }
    }
  end

  def adapt_payment(block)
    properties = block[:properties]
    line_items = properties['lineItems'] || []

    {
      content_type: 'article',
      content: properties['title'] || 'Payment Request',
      content_attributes: {
        items: [
          {
            title: properties['title'] || 'Payment Request',
            description: "#{properties['merchantName']} - #{properties['currencyCode']} #{properties['amount']}",
            link: properties['payment_url']
          }
        ],
        body: format_payment_details(properties, line_items)
      }
    }
  end

  def format_payment_details(properties, line_items)
    details = "**Merchant:** #{properties['merchantName']}\n"
    details += "**Amount:** #{properties['currencyCode']} #{properties['amount']}\n\n"

    if line_items.any?
      details += "**Items:**\n"
      line_items.each do |item|
        details += "- #{item['label']}: #{properties['currencyCode']} #{item['amount']}\n"
      end
    end

    details
  end

  def adapt_generic_content
    # Combine all text blocks into article format
    text_blocks = content_blocks.select { |block| block[:type] == 'text' }

    if text_blocks.any?
      {
        content_type: 'text',
        content: text_blocks.filter_map { |block| block.dig(:properties, 'content') }.join("\n\n"),
        content_attributes: {}
      }
    else
      {
        content_type: 'text',
        content: 'Message',
        content_attributes: {}
      }
    end
  end

  def generate_content
    primary_block = content_blocks.first
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
    current = { 'blocks' => content_blocks, 'template' => template, 'parameters' => parameters }

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
