class Captain::ToolCatalog::ProviderPackLoader
  class InvalidProviderPackError < StandardError; end

  MANIFEST_FILENAME = 'manifest.yml'.freeze
  SCHEMA_PATH = Rails.root.join('enterprise/config/captain/tool_catalog/provider_pack_schema.json').freeze

  def initialize(pack_path:)
    @pack_path = Pathname(pack_path)
  end

  def load
    manifest = parse_manifest
    validation_errors = schema.validate(manifest).to_a
    return manifest if validation_errors.empty?

    raise InvalidProviderPackError, "Invalid provider pack manifest: #{format_errors(validation_errors)}"
  end

  private

  attr_reader :pack_path

  def parse_manifest
    manifest = YAML.safe_load(pack_path.join(MANIFEST_FILENAME).read, aliases: false)
    return manifest if manifest.is_a?(Hash)

    raise InvalidProviderPackError, 'Provider pack manifest must contain an object'
  rescue Errno::ENOENT
    raise InvalidProviderPackError, "Provider pack manifest not found: #{MANIFEST_FILENAME}"
  rescue Psych::Exception => e
    raise InvalidProviderPackError, "Provider pack manifest is not valid YAML: #{e.message}"
  end

  def schema
    @schema ||= JSONSchemer.schema(JSON.parse(SCHEMA_PATH.read))
  end

  def format_errors(errors)
    errors.map do |error|
      pointer = error['data_pointer'].presence || '/'
      "#{pointer} #{error['type']}"
    end.sort.join(', ')
  end
end
