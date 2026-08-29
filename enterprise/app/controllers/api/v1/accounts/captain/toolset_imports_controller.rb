class Api::V1::Accounts::Captain::ToolsetImportsController < Api::V1::Accounts::BaseController
  before_action :ensure_custom_tools_enabled
  before_action -> { check_authorization(Captain::CustomTool) }

  def preview_import
    return render json: { toolsets: github_toolsets } if github_repository_url?

    render json: toolset_service.preview
  rescue Captain::ToolsetService::InvalidManifestError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def import
    tools = toolset_service.import!(toolset_configuration)
    render json: { imported_count: tools.size }, status: :created
  rescue Captain::ToolsetService::InvalidManifestError, Captain::CustomTool::LimitExceededError => e
    render_could_not_create_error(e.message)
  end

  private

  def ensure_custom_tools_enabled
    return if Current.account.feature_enabled?('custom_tools') || Current.account.feature_enabled?('captain_integration_v2')

    render json: { error: 'Custom tools are not enabled for this account' }, status: :forbidden
  end

  def toolset_service
    @toolset_service ||= Captain::ToolsetService.new(
      account: Current.account,
      source: toolset_source,
      source_metadata: toolset_source_metadata
    )
  end

  def toolset_source
    file = params[:file]
    return source_from_url if params[:source].present?

    raise Captain::ToolsetService::InvalidManifestError, 'Select a YAML toolset file or enter a GitHub URL' unless file.respond_to?(:read)
    raise Captain::ToolsetService::InvalidManifestError, 'Toolset file is too large' if file.size > Captain::ToolsetService::MAX_FILE_SIZE

    file.read
  end

  def toolset_source_metadata
    return github_source_metadata if params[:source].present?

    {
      'type' => 'upload',
      'filename' => params[:file].original_filename
    }
  end

  def github_source_metadata
    uri = URI.parse(github_raw_url(params[:source]))
    owner, repository, ref, *path = uri.path.split('/').reject(&:blank?)
    revision = fetch_github_json("https://api.github.com/repos/#{owner}/#{repository}/commits/#{ref}").fetch('sha')

    {
      'type' => 'github',
      'repository' => "#{owner}/#{repository}",
      'path' => path.join('/'),
      'ref' => ref,
      'revision' => revision
    }
  rescue SafeFetch::Error, JSON::ParserError, KeyError => e
    raise Captain::ToolsetService::InvalidManifestError, "Could not resolve the GitHub toolset revision: #{e.message}"
  end

  def source_from_url
    fetch_toolset_source(params[:source])
  rescue SafeFetch::Error => e
    raise Captain::ToolsetService::InvalidManifestError, "Could not fetch the GitHub toolset: #{e.message}"
  end

  def github_repository_url?
    return false if params[:source].blank?

    uri = URI.parse(normalized_github_source)
    uri.scheme == 'https' && uri.host == 'github.com' && uri.path.split('/').count(&:present?) == 2
  rescue URI::InvalidURIError
    false
  end

  def github_toolsets
    uri = URI.parse(normalized_github_source)
    owner, repository = uri.path.split('/').reject(&:blank?)
    repository = repository.delete_suffix('.git')
    repository_data = fetch_github_json("https://api.github.com/repos/#{owner}/#{repository}")
    branch = repository_data.fetch('default_branch')
    contents = fetch_github_json("https://api.github.com/repos/#{owner}/#{repository}/git/trees/#{branch}?recursive=1")

    contents.fetch('tree').filter_map do |item|
      next unless item['type'] == 'blob' && item['path'].match?(%r{\A[^/]+/toolset\.ya?ml\z})

      folder = item['path'].split('/').first
      source = "https://github.com/#{owner}/#{repository}/blob/#{branch}/#{item['path']}"
      toolset_metadata(source, folder)
    end
  rescue SafeFetch::Error, JSON::ParserError, KeyError => e
    raise Captain::ToolsetService::InvalidManifestError, "Could not read the GitHub repository: #{e.message}"
  end

  def fetch_github_json(url)
    SafeFetch.fetch(url, max_bytes: Captain::ToolsetService::MAX_FILE_SIZE, validate_content_type: false) do |result|
      return JSON.parse(result.tempfile.read)
    end
  end

  def toolset_metadata(source, folder)
    preview = Captain::ToolsetService.new(account: Current.account, source: fetch_toolset_source(source)).preview
    {
      name: preview[:name],
      folder: folder,
      description: preview[:description],
      tool_count: preview[:tools].size,
      required_configuration: preview[:fields].filter_map { |field| field[:label] if field[:required] },
      source: source
    }
  end

  def fetch_toolset_source(source)
    SafeFetch.fetch(github_raw_url(source), max_bytes: Captain::ToolsetService::MAX_FILE_SIZE, validate_content_type: false) do |result|
      return result.tempfile.read
    end
  end

  def github_raw_url(source)
    uri = URI.parse(normalized_github_source(source))
    return uri.to_s if uri.scheme == 'https' && uri.host == 'raw.githubusercontent.com'

    validate_github_uri!(uri)

    segments = uri.path.split('/').reject(&:blank?)
    validate_github_path!(segments)

    owner, repository, = segments
    repository = repository.delete_suffix('.git')
    ref, path = github_ref_and_path(segments.drop(2))
    "https://raw.githubusercontent.com/#{owner}/#{repository}/#{ref}/#{path.join('/')}"
  rescue URI::InvalidURIError
    raise Captain::ToolsetService::InvalidManifestError, 'Enter a valid GitHub URL'
  end

  def normalized_github_source(source = params[:source])
    value = source.to_s.strip
    return value if value.start_with?('https://')

    segments = value.split('/')
    validate_github_shorthand!(segments)

    owner, repository, *path = segments
    view = path.last&.match?(/toolset\.ya?ml\z/) ? 'blob' : 'tree'
    suffix = path.any? ? "/#{view}/HEAD/#{path.join('/')}" : ''
    "https://github.com/#{owner}/#{repository}#{suffix}"
  end

  def validate_github_uri!(uri)
    return if uri.scheme == 'https' && uri.host == 'github.com'

    raise Captain::ToolsetService::InvalidManifestError, 'Enter a valid GitHub URL'
  end

  def validate_github_path!(segments)
    return if segments.size >= 2

    raise Captain::ToolsetService::InvalidManifestError, 'Enter a GitHub repository, folder, or toolset.yml URL'
  end

  def validate_github_shorthand!(segments)
    return if segments.size.between?(2, 10) && segments.all? { |segment| segment.match?(/\A[\w.-]+\z/) }

    raise Captain::ToolsetService::InvalidManifestError, 'Enter a valid GitHub URL or owner/repository/tool path'
  end

  def github_ref_and_path(location)
    view, ref, *path = location
    return ['HEAD', ['toolset.yml']] unless %w[blob tree].include?(view)

    path << 'toolset.yml' if view == 'tree'
    [ref, path]
  end

  def toolset_configuration
    JSON.parse(params[:configuration].presence || '{}')
  rescue JSON::ParserError
    raise Captain::ToolsetService::InvalidManifestError, 'Toolset configuration must be valid JSON'
  end
end
