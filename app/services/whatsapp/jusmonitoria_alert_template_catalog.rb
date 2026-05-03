class Whatsapp::JusmonitoriaAlertTemplateCatalog
  def initialize(channel:, definitions:, prefix:, pattern:, language:)
    @channel = channel
    @definitions = definitions
    @prefix = prefix
    @pattern = pattern
    @language = language
  end

  def available_templates
    templates = serialized_canonical_templates
    templates.concat(fallback_options_for_missing_definitions(templates))
    templates.uniq { |template| template[:name] }.sort_by { |template| template[:version] || 0 }
  end

  def template_category(template)
    template&.dig('category').presence || template&.dig('template_category').presence
  end

  def template_parameter_format(template)
    template&.dig('parameter_format').presence || template&.dig('template_parameter_format').presence
  end

  def template_body_text(template)
    body = Array(template&.dig('components')).find { |component| component['type'].to_s.casecmp('BODY').zero? }
    body&.dig('text').presence
  end

  def template_header_format(template, name:)
    header = Array(template&.dig('components')).find { |component| component['type'].to_s.casecmp('HEADER').zero? }
    header&.dig('format').presence || template_definition_for(name)[:header_format]
  end

  def template_header_media_url(_template, name:)
    template_definition_for(name)[:header_media_url]
  end

  def template_footer_text(template, name:)
    footer = Array(template&.dig('components')).find { |component| component['type'].to_s.casecmp('FOOTER').zero? }
    footer&.dig('text').presence || template_definition_for(name)[:footer_text]
  end

  private

  def serialized_canonical_templates
    Array(@channel.message_templates)
      .select { |template| canonical_template?(template) }
      .map { |template| serialize_template_option(template) }
  end

  def canonical_template?(template)
    template['name'].to_s.match?(@pattern) &&
      template['language'].to_s.casecmp(@language).zero?
  end

  def serialize_template_option(template)
    name = template&.dig('name').presence || default_name
    definition = template_definition_for(name)
    {
      id: template&.dig('id'),
      name: name,
      version: template_version(name),
      language: @language,
      status: template&.dig('status').presence ? template['status'].to_s.downcase : 'missing',
      category: template_category(template) || definition[:category],
      parameter_format: template_parameter_format(template) || definition[:parameter_format],
      body_text: template_body_text(template) || definition[:body_text],
      header_format: template_header_format(template, name: name),
      header_media_url: template_header_media_url(template, name: name),
      footer_text: template_footer_text(template, name: name)
    }.compact
  end

  def fallback_options_for_missing_definitions(templates)
    existing_names = templates.pluck(:name)
    @definitions.keys.reject { |name| existing_names.include?(name) }.map do |name|
      serialize_template_option({ 'name' => name, 'language' => @language })
    end
  end

  def template_version(name)
    name.to_s.delete_prefix(@prefix).to_i
  end

  def template_definition_for(name)
    @definitions[name] || @definitions[default_name]
  end

  def default_name
    @definitions.keys.first
  end
end
