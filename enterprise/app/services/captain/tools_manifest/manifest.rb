# Reads a toolset.yml from chatwoot/tools. Toolsets are validated before they are merged there, so this only
# parses the file and fills in the defaults the installer relies on. The model still validates every tool it saves.
class Captain::ToolsManifest::Manifest
  TOOL_DEFAULTS = { 'auth_config' => {}, 'param_schema' => [], 'enabled' => true }.freeze
  FIELD_DEFAULTS = { 'type' => 'string', 'required' => false }.freeze

  def self.parse(source)
    manifest = YAML.safe_load(source)
    manifest.merge(
      'headers' => manifest['headers'] || {},
      'inputs' => with_field_defaults(manifest['inputs']),
      'secrets' => with_field_defaults(manifest['secrets']),
      'tools' => manifest.fetch('tools').map { |tool| TOOL_DEFAULTS.merge(tool.compact) }
    )
  end

  def self.with_field_defaults(fields)
    (fields || {}).transform_values { |definition| FIELD_DEFAULTS.merge(definition.compact) }
  end
  private_class_method :with_field_defaults
end
