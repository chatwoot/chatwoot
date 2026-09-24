# Installs a toolset from a public GitHub repository onto an assistant.
#
# The toolset is addressed as owner/repository/folder and pinned to a commit: the
# given revision, or the latest commit on the default branch. Installing the same
# commit again is a no-op. Installing another commit updates the existing tools in
# place, matched by manifest tool id, so slugs and the user-owned enabled flag stay.
class Captain::ToolsManifest::InstallService
  class InstallError < StandardError; end

  SOURCE = 'github'.freeze
  SOURCE_PATTERN = %r{\A([\w.-]+)/([\w.-]+)/([\w.-]+)\z}
  DOT_SEGMENT_PATTERN = /\A\.+\z/
  REVISION_PATTERN = /\A[0-9a-f]{40}\z/
  MANIFEST_FILE = 'toolset.yml'.freeze
  REQUEST_TIMEOUT = 10
  CONFIGURATION_SECTIONS = %w[inputs secrets].freeze

  def initialize(assistant:, source:, configuration:, revision: nil)
    @assistant = assistant
    @source = source
    @configuration = configuration
    @revision = revision
  end

  def perform
    parse_source!
    revision = @revision || latest_revision
    return installed_tools if installed_tools.any? && installed_tools.all? { |tool| tool.source_metadata['revision'] == revision }

    manifest_source = fetch("https://raw.githubusercontent.com/#{@repository}/#{revision}/#{@path}/#{MANIFEST_FILE}")
    manifest = Captain::ToolsManifest::Validator.new(manifest_source).perform
    values = configuration_values!(manifest)

    install!(manifest, values, source_metadata(manifest, revision, manifest_source))
  end

  private

  def parse_source!
    owner, repository, path = SOURCE_PATTERN.match(@source.to_s)&.captures
    segments = [owner, repository, path]
    raise InstallError, 'Source must be owner/repository/folder' if owner.nil? || segments.any? { |segment| segment.match?(DOT_SEGMENT_PATTERN) }
    raise InstallError, 'Revision must be a full 40-character commit SHA' if @revision && !REVISION_PATTERN.match?(@revision)

    @repository = "#{owner}/#{repository}"
    @path = path
  end

  def latest_revision
    revision = fetch_latest_revision.strip
    raise InstallError, "Could not resolve the latest commit of #{@repository}" unless REVISION_PATTERN.match?(revision)

    revision
  end

  # The token only raises the GitHub API rate limit, so an expired or revoked one falls back to an unauthenticated lookup
  def fetch_latest_revision
    url = "https://api.github.com/repos/#{@repository}/commits/HEAD"
    headers = { 'Accept' => 'application/vnd.github.sha' }
    token = GlobalConfigService.load('CAPTAIN_TOOLS_GITHUB_TOKEN', nil)
    response = get(url, token.present? ? headers.merge('Authorization' => "Bearer #{token}") : headers)
    if token.present? && response.code == 401
      Rails.logger.warn('[Captain::ToolsManifest] CAPTAIN_TOOLS_GITHUB_TOKEN was rejected by GitHub, retrying without it')
      response = get(url, headers)
    end
    body!(response, url)
  end

  def fetch(url)
    body!(get(url), url)
  end

  # Only GitHub's own hosts are requested and path segments are validated, so SafeFetch's SSRF checks aren't needed
  def get(url, headers = {})
    HTTParty.get(url, headers: headers, timeout: REQUEST_TIMEOUT)
  rescue HTTParty::Error, SocketError, Timeout::Error, SystemCallError, OpenSSL::SSL::SSLError => e
    raise InstallError, "Could not fetch #{url}: #{e.message}"
  end

  def body!(response, url)
    raise InstallError, "Could not fetch #{url}: #{response.code}" unless response.success?

    response.body
  end

  def installed_tools
    @installed_tools ||= @assistant.custom_tools
                                   .where("source_metadata->>'source' = ?", SOURCE)
                                   .where("source_metadata->>'repository' = ? AND source_metadata->>'path' = ?", @repository, @path)
                                   .to_a
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

    unknown_names = values.keys - definitions.keys
    raise InstallError, "Unknown #{section}: #{unknown_names.join(', ')}" if unknown_names.any?

    # blank? would treat false as missing, which is a valid value for a boolean
    missing = definitions.find { |name, definition| definition['required'] && values[name].to_s.strip.empty? }
    raise InstallError, "#{missing.last['label']} is required" if missing

    values
  end

  def source_metadata(manifest, revision, manifest_source)
    {
      'source' => SOURCE,
      'repository' => @repository,
      'path' => @path,
      'revision' => revision,
      'version' => manifest['version'],
      'manifest_digest' => "sha256:#{Digest::SHA256.hexdigest(manifest_source)}",
      'installation_id' => installed_tools.first&.source_metadata&.dig('installation_id') || SecureRandom.uuid
    }
  end

  def install!(manifest, values, metadata)
    existing_tools = installed_tools.index_by { |tool| tool.source_metadata['tool_id'] }

    ApplicationRecord.transaction do
      existing_tools.except(*manifest['tools'].pluck('id')).each_value(&:destroy!)
      manifest['tools'].map { |tool| save_tool!(existing_tools[tool['id']], tool, tool_attributes(tool, manifest, values, metadata)) }
    end
  rescue ActiveRecord::RecordInvalid => e
    raise InstallError, "#{e.record.title}: #{e.record.errors.full_messages.to_sentence}"
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
