class Captain::ToolCatalog::TemplateSelection
  Selection = Struct.new(:pack, :items, keyword_init: true) do
    def serialized
      items.map do |entry|
        {
          'template_key' => entry.fetch(:template).fetch('key'),
          'template_version' => entry.fetch(:template).fetch('version'),
          'configuration' => entry.fetch(:configuration)
        }
      end
    end

    def required_scopes(selected_items = items)
      selected_items.flat_map { |item| item.fetch(:template).fetch('effective_scopes') }.uniq.sort
    end
  end

  def initialize(registry: Captain::ToolCatalog::ProviderPackRegistry.default)
    @registry = registry
  end

  def resolve(provider_key:, templates:)
    pack = registry.find(provider_key)
    normalized_templates = Array(templates).map { |template| template.to_h.stringify_keys }
    validate_template_list!(normalized_templates)

    items = normalized_templates.map { |selection| resolve_template(pack, selection) }
    Selection.new(pack: pack, items: items)
  end

  private

  attr_reader :registry

  def validate_template_list!(templates)
    raise Captain::ToolCatalog::WorkflowError, 'templates_required' if templates.empty?

    keys = templates.pluck('template_key')
    raise Captain::ToolCatalog::WorkflowError, 'duplicate_templates' if keys.uniq.length != keys.length
  end

  def resolve_template(pack, selection)
    template = pack.fetch('templates').find { |candidate| candidate.fetch('key') == selection['template_key'] }
    raise Captain::ToolCatalog::WorkflowError, 'template_not_found' if template.blank?
    raise Captain::ToolCatalog::WorkflowError, 'template_version_changed' if template.fetch('version') != selection['template_version']
    raise Captain::ToolCatalog::WorkflowError, 'template_unavailable' unless installable?(template)

    configuration = selection.fetch('configuration', {})
    validate_configuration!(template, configuration)
    { template: template, configuration: configuration }
  end

  def installable?(template)
    template.fetch('availability') == 'available' && template.fetch('model_visible')
  end

  def validate_configuration!(template, configuration)
    valid = configuration.is_a?(Hash) && JSONSchemer.schema(template.fetch('configuration_schema')).valid?(configuration)
    raise Captain::ToolCatalog::WorkflowError, 'invalid_configuration' unless valid

    Captain::ToolCatalog::ProviderPackValidator.new.reject_secret_literals!(configuration, 'installation configuration')
  rescue Captain::ToolCatalog::ProviderPackError
    raise Captain::ToolCatalog::WorkflowError, 'secret_configuration_rejected'
  end
end
