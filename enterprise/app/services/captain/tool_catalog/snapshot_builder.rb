require 'digest'

class Captain::ToolCatalog::SnapshotBuilder
  def initialize(pack:, entry:, integration_hook:)
    @pack = pack
    @template = entry.fetch(:template)
    @configuration = entry.fetch(:configuration)
    @integration_hook = integration_hook
  end

  def attributes
    identity_attributes.merge(
      definition_digest: definition_digest,
      definition: definition,
      configuration: configuration,
      input_schema: template.fetch('input_schema'),
      output_schema: template.fetch('output_schema'),
      risk_class: template.fetch('risk_class'),
      integration_hook_id: integration_hook&.id,
      endpoint_url: nil,
      auth_type: 'none',
      auth_config: {}
    )
  end

  private

  attr_reader :pack, :template, :configuration, :integration_hook

  def identity_attributes
    {
      slug: template.fetch('stable_name'),
      title: template.fetch('name'),
      description: template.fetch('description'),
      source_kind: 'catalog',
      provider_key: pack.dig('provider', 'key'),
      category_key: template.fetch('category_key'),
      template_key: template.fetch('key'),
      template_version: template.fetch('version')
    }
  end

  def definition
    @definition ||= canonicalize(
      'schema_version' => pack.fetch('schema_version'),
      'provider' => pack.fetch('provider'),
      'authentication' => pack.fetch('authentication'),
      'allowed_origins' => pack.fetch('allowed_origins'),
      'operations' => recipe_operations,
      'recipe' => template.fetch('recipe')
    )
  end

  def recipe_operations
    operation_keys = template.fetch('recipe').pluck('operation_key')
    pack.fetch('operations').select { |operation| operation_keys.include?(operation.fetch('key')) }
  end

  def definition_digest
    digest_payload = canonicalize(
      'definition' => definition,
      'input_schema' => template.fetch('input_schema'),
      'output_schema' => template.fetch('output_schema'),
      'risk_class' => template.fetch('risk_class'),
      'template_version' => template.fetch('version')
    )
    "sha256:#{Digest::SHA256.hexdigest(JSON.generate(digest_payload))}"
  end

  def canonicalize(value)
    case value
    when Hash
      value.keys.sort.index_with { |key| canonicalize(value.fetch(key)) }
    when Array
      value.map { |item| canonicalize(item) }
    else
      value
    end
  end
end
