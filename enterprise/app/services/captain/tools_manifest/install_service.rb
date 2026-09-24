# Installs a toolset from a public GitHub repository onto an assistant.
#
# The toolset is pinned to a commit: the given revision, or the latest commit on the
# default branch. Installing the same commit again is a no-op once every tool is
# present. Otherwise the existing tools are updated in place, matched by manifest
# tool id so slugs and the user-owned enabled flag stay, and missing ones are added.
class Captain::ToolsManifest::InstallService
  class InstallError < StandardError; end

  SOURCE = 'github'.freeze
  CONFIGURATION_SECTIONS = %w[inputs secrets].freeze
  NUMBER_PATTERN = /\A-?\d+(\.\d+)?\z/

  def initialize(assistant:, source:, configuration:, revision: nil)
    @assistant = assistant
    @source = source
    @configuration = configuration
    @revision = revision
  end

  def perform
    @github_source = Captain::ToolsManifest::GithubSource.new(@source)
    if @revision && !Captain::ToolsManifest::GithubSource::REVISION_PATTERN.match?(@revision)
      raise InstallError, 'Revision must be a full 40-character commit SHA'
    end

    revision = @revision || @github_source.latest_revision
    manifest_source = @github_source.manifest(revision)
    manifest = Captain::ToolsManifest::Validator.new(manifest_source).perform
    return installed_tools if complete_install?(installed_tools, manifest, revision)

    values = configuration_values!(manifest)

    install!(manifest, values, revision, manifest_source)
  end

  private

  # Installed at this commit with every manifest tool present, so there is nothing to add or update
  def complete_install?(tools, manifest, revision)
    tools.any? &&
      tools.all? { |tool| tool.source_metadata['revision'] == revision } &&
      (manifest['tools'].pluck('id') - tools.map { |tool| tool.source_metadata['tool_id'] }).empty?
  end

  def installed_tools
    @installed_tools ||= @assistant.custom_tools.from_github(@github_source.repository, @github_source.path).to_a
  end

  def configuration_values!(manifest)
    raise InstallError, 'Configuration must be an object' unless @configuration.is_a?(Hash)

    configuration = @configuration.deep_stringify_keys
    unknown_sections = configuration.keys - CONFIGURATION_SECTIONS
    raise InstallError, "Unknown configuration sections: #{unknown_sections.join(', ')}" if unknown_sections.any?

    CONFIGURATION_SECTIONS.index_with { |section| section_values!(manifest[section], configuration.fetch(section, {}), section) }
  end

  def section_values!(definitions, values, section)
    raise InstallError, "#{section} must be an object" unless values.is_a?(Hash)

    validate_values!(definitions, values, section)

    # blank? would treat false as missing, which is a valid value for a boolean
    missing = definitions.find { |name, definition| definition['required'] && values[name].to_s.strip.empty? }
    raise InstallError, "#{missing.last['label']} is required" if missing

    values
  end

  def validate_values!(definitions, values, section)
    unknown_names = values.keys - definitions.keys
    raise InstallError, "Unknown #{section}: #{unknown_names.join(', ')}" if unknown_names.any?

    invalid = values.find { |name, value| !valid_value?(definitions[name], value) }
    raise InstallError, "#{definitions[invalid.first]['label']} has an invalid value" if invalid
  end

  # Values are interpolated into URLs, auth and request bodies, so they must match the declared type.
  # Numbers may arrive as strings from form inputs; empty optional values are handled by the required check.
  def valid_value?(definition, value)
    return true if value.nil? || value == ''

    case definition['type']
    when 'boolean' then [true, false].include?(value)
    when 'number' then value.is_a?(Numeric) || value.to_s.match?(NUMBER_PATTERN)
    when 'select' then Array(definition['options']).include?(value)
    else value.is_a?(String)
    end
  end

  def source_metadata(manifest, revision, manifest_source, current_tools)
    {
      'source' => SOURCE,
      'repository' => @github_source.repository,
      'path' => @github_source.path,
      'revision' => revision,
      'version' => manifest['version'],
      'manifest_digest' => "sha256:#{Digest::SHA256.hexdigest(manifest_source)}",
      'installation_id' => current_tools.first&.source_metadata&.fetch('installation_id') || SecureRandom.uuid
    }
  end

  def install!(manifest, values, revision, manifest_source)
    ApplicationRecord.transaction do
      # Serializes installs on the assistant; tools are re-read under the lock so a concurrent install is seen
      Captain::Assistant.lock.find(@assistant.id)
      current_tools = @assistant.custom_tools.from_github(@github_source.repository, @github_source.path).to_a
      next current_tools if complete_install?(current_tools, manifest, revision)

      save_tools!(manifest, values, current_tools, source_metadata(manifest, revision, manifest_source, current_tools))
    end
  rescue ActiveRecord::RecordInvalid => e
    raise InstallError, "#{e.record.title}: #{e.record.errors.full_messages.to_sentence}"
  end

  def save_tools!(manifest, values, current_tools, metadata)
    existing_tools = current_tools.index_by { |tool| tool.source_metadata['tool_id'] }
    existing_tools.except(*manifest['tools'].pluck('id')).each_value(&:destroy!)
    manifest['tools'].map { |tool| save_tool!(existing_tools[tool['id']], tool, tool_attributes(tool, manifest, values, metadata)) }
  end

  def save_tool!(existing_tool, tool, attributes)
    return existing_tool.tap { |record| record.update!(attributes) } if existing_tool

    @assistant.custom_tools.create!(attributes.merge(account: @assistant.account, enabled: tool['enabled']))
  end

  # Everything except enabled comes from the manifest; enabled belongs to the user once a tool exists
  def tool_attributes(tool, manifest, values, metadata)
    {
      title: tool['title'],
      description: tool['description'],
      http_method: tool['http_method'],
      endpoint_url: interpolate(tool['endpoint_url'], values),
      auth_type: tool['auth_type'],
      auth_config: interpolate(tool['auth_config'], values),
      param_schema: tool['param_schema'],
      request_template: interpolate(tool['request_template'], values),
      response_template: tool['response_template'],
      headers: manifest['headers'],
      source_metadata: metadata.merge('tool_id' => tool['id'])
    }
  end

  def interpolate(value, values)
    case value
    when String
      value.gsub(Captain::ToolsManifest::Validator::INSTALL_PLACEHOLDER_PATTERN) do
        values[Regexp.last_match(1).downcase].fetch(Regexp.last_match(2), '').to_s
      end
    when Hash
      value.transform_values { |item| interpolate(item, values) }
    else
      value
    end
  end
end
