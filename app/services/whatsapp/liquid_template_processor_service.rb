class Whatsapp::LiquidTemplateProcessorService
  LIQUID_EXPRESSION = /\{\{\s*(.+?)\s*\}\}/

  module JsonEscapeFilter
    def json_escape(input)
      input.to_s.to_json[1..-2]
    end
  end

  pattr_initialize [:campaign!, :contact!]

  def process_template_params(template_params)
    return template_params if template_params.blank?

    template_params_copy = template_params.deep_dup
    processed_params = template_params_copy['processed_params']

    return template_params_copy if processed_params.blank?

    rendered_params = render_liquid(processed_params)
    return nil if blank_render?(processed_params, rendered_params)

    template_params_copy.merge('processed_params' => rendered_params)
  end

  private

  def render_liquid(processed_params)
    raw = processed_params.to_json
    rewritten = raw.gsub(LIQUID_EXPRESSION) { "{{ #{Regexp.last_match(1)} | json_escape }}" }
    rendered = Liquid::Template.parse(rewritten).render!(drops, filters: [JsonEscapeFilter])
    JSON.parse(rendered)
  rescue Liquid::Error, JSON::ParserError
    processed_params
  end

  def drops
    {
      'contact' => ContactDrop.new(contact),
      'agent' => UserDrop.new(campaign.sender),
      'inbox' => InboxDrop.new(campaign.inbox),
      'account' => AccountDrop.new(campaign.account)
    }
  end

  def blank_render?(original, rendered)
    case original
    when Hash then blank_render_in_hash?(original, rendered)
    when Array then blank_render_in_array?(original, rendered)
    when String then original.match?(LIQUID_EXPRESSION) && rendered.to_s.blank?
    else false
    end
  end

  def blank_render_in_hash?(original, rendered)
    return false unless rendered.is_a?(Hash)

    original.any? { |key, value| blank_render?(value, rendered[key]) }
  end

  def blank_render_in_array?(original, rendered)
    return false unless rendered.is_a?(Array)

    original.each_with_index.any? { |value, index| blank_render?(value, rendered[index]) }
  end
end
