module Liquidable
  extend ActiveSupport::Concern

  included do
    before_create :process_liquid_in_content
    before_create :process_liquid_in_template_params
  end

  private

  def message_drops
    {
      'contact' => ContactDrop.new(conversation.contact),
      'agent' => UserDrop.new(sender || conversation.assignee),
      'conversation' => ConversationDrop.new(conversation),
      'inbox' => InboxDrop.new(inbox),
      'account' => AccountDrop.new(conversation.account)
    }
  end

  def liquid_processable_message?
    content.present? && (message_type == 'outgoing' || message_type == 'template')
  end

  def process_liquid_in_content
    return unless liquid_processable_message?

    content_to_render, additional_drops = if whatsapp_template_message?
                                            whatsapp_template_content
                                          else
                                            [content, {}]
                                          end

    template = Liquid::Template.parse(modified_liquid_content(content_to_render))
    self.content = template.render(message_drops.merge(additional_drops))
  rescue Liquid::Error
    # If there is an error in the liquid syntax, we don't want to process it
  end

  def modified_liquid_content(message_content)
    # This regex is used to match the code blocks in the content
    # We don't want to process liquid in code blocks
    message_content.gsub(/`(.*?)`/m, '{% raw %}`\\1`{% endraw %}')
  end

  def process_liquid_in_template_params
    return unless template_params_present? && liquid_processable_template_params?

    processed_params = process_liquid_in_hash(template_params_data['processed_params'])

    # Update the additional_attributes with processed template_params
    self.additional_attributes = additional_attributes.merge(
      'template_params' => template_params_data.merge('processed_params' => processed_params)
    )
  rescue Liquid::Error
    # If there is an error in the liquid syntax, we don't want to process it
  end

  def template_params_present?
    additional_attributes&.dig('template_params', 'processed_params').present?
  end

  def liquid_processable_template_params?
    message_type == 'outgoing' || message_type == 'template'
  end

  def template_params_data
    additional_attributes['template_params']
  end

  def whatsapp_template_message?
    inbox.channel_type == 'Channel::Whatsapp' && additional_attributes&.dig('template_params').is_a?(Hash)
  end

  def whatsapp_template_content
    body_params = whatsapp_template_body_params
    rendered_params = {}

    content_to_render = content.gsub(/{{\s*([^}]+?)\s*}}/) do |placeholder|
      key = Regexp.last_match(1)

      if body_params.key?(key)
        rendered_value = process_liquid_value(body_params[key])
        structured_value = rendered_value.is_a?(Hash) && %w[currency date_time].include?(rendered_value['type'])
        rendered_params[rendered_params.length.to_s] = structured_value ? rendered_value['fallback_value'].to_s : rendered_value.to_s
        "{{ __whatsapp_template_params['#{rendered_params.length - 1}'] }}"
      elsif key.match?(/\A(?:\d+|[a-z][a-z0-9_]*)\z/)
        "{% raw %}#{placeholder}{% endraw %}"
      else
        placeholder
      end
    end

    [content_to_render, { '__whatsapp_template_params' => rendered_params }]
  end

  def whatsapp_template_body_params
    normalized_params = Whatsapp::TemplateParameterConverterService.new(template_params_data.deep_dup, nil).normalize_to_enhanced
    normalized_params.dig('processed_params', 'body') || {}
  end

  def process_liquid_in_hash(hash)
    return hash unless hash.is_a?(Hash)

    hash.transform_values { |value| process_liquid_value(value) }
  end

  def process_liquid_value(value)
    case value
    when String
      process_liquid_string(value)
    when Hash
      process_liquid_in_hash(value)
    when Array
      process_liquid_array(value)
    else
      value
    end
  end

  def process_liquid_array(array)
    array.map { |item| process_liquid_value(item) }
  end

  def process_liquid_string(string)
    return string if string.blank?

    template = Liquid::Template.parse(string)
    template.render(message_drops)
  rescue Liquid::Error
    string
  end
end
