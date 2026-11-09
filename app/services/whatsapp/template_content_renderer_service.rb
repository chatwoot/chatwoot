class Whatsapp::TemplateContentRendererService
  def initialize(content:, body_params:, value_renderer:, message_drops:)
    @content = content
    @body_params = body_params
    @value_renderer = value_renderer
    @message_drops = message_drops
    @parameter_builder = Whatsapp::PopulateTemplateParametersService.new
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
    parameter_present = @body_params.key?(key)
    return placeholder unless parameter_present || key.match?(/\A(?:\d+|[a-z][a-z0-9_]*)\z/)

    replacement_key = "#{replacement_prefix}#{replacements.length}__"
    replacements[replacement_key] = parameter_present ? display_value(@value_renderer.call(@body_params[key])) : placeholder
    replacement_key
  end

  def display_value(rendered_value)
    parameter = @parameter_builder.build_parameter(rendered_value)
    return parameter[:text] if parameter[:type] == 'text'

    parameter.dig(parameter[:type].to_sym, :fallback_value).to_s
  end

  def modified_liquid_content(content)
    content.gsub(/`(.*?)`/m, '{% raw %}`\\1`{% endraw %}')
  end
end
