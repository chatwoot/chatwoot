require 'digest'

class Captain::ToolCatalog::ProviderPackCompiler
  def initialize(pack_path:)
    @pack_path = Pathname(pack_path)
    @source_loader = Captain::ToolCatalog::ProviderPackSourceLoader.new(pack_path: pack_path)
    @validator = Captain::ToolCatalog::ProviderPackValidator.new
  end

  def compile
    @manifest = Captain::ToolCatalog::ProviderPackLoader.new(pack_path: pack_path).load
    validator.validate_manifest!(manifest)

    canonical_pack = canonicalize(compiled_pack)
    canonical_pack['digest'] = "sha256:#{Digest::SHA256.hexdigest(JSON.generate(canonical_pack))}"
    deep_freeze(canonical_pack)
  end

  private

  attr_reader :manifest, :pack_path, :source_loader, :validator

  def compiled_pack
    {
      'schema_version' => manifest.fetch('schema_version'),
      'provider' => manifest.slice('key', 'name', 'description', 'api_version'),
      'authentication' => manifest.fetch('authentication'),
      'allowed_origins' => validator.validated_origins(manifest.fetch('allowed_origins')),
      'sources' => compile_sources,
      'categories' => manifest.fetch('categories').sort_by { |category| category.fetch('key') },
      'operations' => compile_operations,
      'templates' => compile_templates
    }
  end

  def compile_sources
    sources = source_loader.load_sources
    validator.validate_sources!(sources)
    sources.fetch('sources').sort_by { |source| [source.fetch('url'), source.fetch('revision')] }
  end

  def compile_operations
    operations = manifest.fetch('operations').map do |operation|
      source = source_loader.load_operation(operation)
      validator.reject_secret_literals!(source.definition, operation.fetch('reference'))
      validator.validate_operation_request!(source.request, manifest.fetch('allowed_origins'))
      validate_operation_fixtures!(operation)

      operation.slice('key', 'source', 'visibility', 'scopes', 'risk_class').merge(
        'scopes' => operation.fetch('scopes').sort,
        'definition' => source.definition,
        'request' => source.request
      )
    end
    operations.sort_by { |operation| operation.fetch('key') }
  end

  def validate_operation_fixtures!(operation)
    fixture_paths = [operation.dig('fixtures', 'success'), *operation.dig('fixtures', 'errors')]
    fixture_paths.each do |fixture_path|
      fixture = source_loader.load_fixture(fixture_path)
      validator.reject_secret_literals!(fixture, fixture_path)
    end
  end

  def compile_templates
    Captain::ToolCatalog::ProviderPackTemplateCompiler.new(
      manifest: manifest,
      source_loader: source_loader,
      validator: validator
    ).compile
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

  def deep_freeze(value)
    if value.is_a?(Hash)
      value.each do |key, child|
        deep_freeze(key)
        deep_freeze(child)
      end
    elsif value.is_a?(Array)
      value.each { |child| deep_freeze(child) }
    end
    value.freeze
  end
end
