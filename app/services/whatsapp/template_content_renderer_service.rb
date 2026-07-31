class Whatsapp::TemplateContentRendererService
  def initialize(content:, body_params:, value_renderer:, message_drops:)
    @content = content
    @body_params = body_params
    @value_renderer = value_renderer
    @message_drops = message_drops
  end

  def perform
    content_to_render, replacements, replacement_pattern = prepare_content
    rendered_content = Liquid::Template.parse(modified_liquid_content(content_to_render)).render(@message_drops)
    return rendered_content unless replacement_pattern

    rendered_content.gsub(replacement_pattern) { |placeholder| replacements.fetch(placeholder) }
  end

  private

  def prepare_content
    replacements = {}
    replacement_prefix = "__chatwoot_whatsapp_template_param_#{SecureRandom.hex(8)}_"
    content_to_render = @content.gsub(/{{\s*([^}]+?)\s*}}/) do |placeholder|
      replace_placeholder(placeholder, Regexp.last_match(1), replacement_prefix, replacements)
    end
    replacement_pattern = /#{Regexp.escape(replacement_prefix)}\d+__/ if replacements.any?

    [content_to_render, replacements, replacement_pattern]
  end

  def replace_placeholder(placeholder, key, replacement_prefix, replacements)
    return unresolved_placeholder(placeholder, key) unless @body_params.key?(key)

    rendered_value = @value_renderer.call(@body_params[key])
    replacement_key = "#{replacement_prefix}#{replacements.length}__"
    replacements[replacement_key] = display_value(rendered_value)
    replacement_key
  end

  def unresolved_placeholder(placeholder, key)
    return "{% raw %}#{placeholder}{% endraw %}" if key.match?(/\A(?:\d+|[a-z][a-z0-9_]*)\z/)

    placeholder
  end

  def display_value(rendered_value)
    structured_value = rendered_value.is_a?(Hash) && %w[currency date_time].include?(rendered_value['type'])
    structured_value ? rendered_value['fallback_value'].to_s : rendered_value.to_s
  end

  def modified_liquid_content(content)
    content.gsub(/`(.*?)`/m, '{% raw %}`\\1`{% endraw %}')
  end
end
