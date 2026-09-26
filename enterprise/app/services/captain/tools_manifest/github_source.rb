# A toolset folder in a public GitHub repository, addressed as owner/repository/folder
# or as a github.com link to the folder or its toolset.yml. Links must point at the
# default branch, since installs always use its latest commit.
class Captain::ToolsManifest::GithubSource
  class SourceError < StandardError; end

  INVALID_SOURCE_MESSAGE = 'Enter a GitHub URL or owner/repository/folder'.freeze
  SEGMENT_PATTERN = /\A[\w.-]+\z/
  REVISION_PATTERN = /\A[0-9a-f]{40}\z/
  DOT_SEGMENT_PATTERN = /\A\.+\z/
  MANIFEST_FILE = 'toolset.yml'.freeze
  API_URL = 'https://api.github.com'.freeze
  RAW_URL = 'https://raw.githubusercontent.com'.freeze
  REQUEST_TIMEOUT = 10

  attr_reader :repository, :path

  def initialize(source)
    raise SourceError, INVALID_SOURCE_MESSAGE unless source.is_a?(String)

    owner, repository, @path, @ref = parse(source.strip)
    raise SourceError, INVALID_SOURCE_MESSAGE unless [owner, repository, @path].all? { |segment| valid_segment?(segment) }

    # GitHub ignores case in owner and repository names, so they are lowercased to avoid duplicate installs.
    # Folder names are case-sensitive, so the folder is kept as typed.
    @repository = "#{owner}/#{repository}".downcase
  end

  def latest_revision
    ensure_default_branch! if @ref
    revision = github_api("/repos/#{repository}/commits/HEAD", accept: 'application/vnd.github.sha').strip
    raise SourceError, "Could not resolve the latest commit of #{repository}" unless REVISION_PATTERN.match?(revision)

    revision
  end

  def manifest(revision)
    fetch("#{RAW_URL}/#{repository}/#{revision}/#{path}/#{MANIFEST_FILE}")
  end

  private

  def parse(source)
    return parse_url(source) if source.start_with?('https://')

    parts = source.split('/', -1)
    parts.size == 3 ? parts : []
  end

  def valid_segment?(segment)
    segment.to_s.match?(SEGMENT_PATTERN) && !segment.match?(DOT_SEGMENT_PATTERN)
  end

  # github.com/<owner>/<repo>/tree/<ref>/<folder> or .../blob/<ref>/<folder>/toolset.yml, where <ref> may contain slashes
  def parse_url(source)
    uri = URI.parse(source)
    return [] unless uri.host == 'github.com'

    owner, repository, view, *location = uri.path.split('/').compact_blank
    location = folder_location(view, location)
    return [] if location.nil? || location.size < 2

    [owner, repository, location.last, location[0..-2].join('/')]
  rescue URI::InvalidURIError
    []
  end

  def folder_location(view, location)
    return location if view == 'tree'

    location[0..-2] if view == 'blob' && location.last == MANIFEST_FILE
  end

  def ensure_default_branch!
    default_branch = JSON.parse(github_api("/repos/#{repository}", accept: 'application/vnd.github+json')).fetch('default_branch')
    return if @ref == default_branch

    raise SourceError, "Only the default branch (#{default_branch}) can be installed"
  rescue JSON::ParserError, KeyError
    raise SourceError, "Could not read #{repository} from GitHub"
  end

  # The token only raises the GitHub API rate limit, so an expired or revoked one falls back to an unauthenticated request
  def github_api(path, accept:)
    url = "#{API_URL}#{path}"
    headers = { 'Accept' => accept }
    token = GlobalConfigService.load('CAPTAIN_TOOLS_GITHUB_TOKEN', nil)
    code, body = get(url, token.present? ? headers.merge('Authorization' => "Bearer #{token}") : headers)
    if token.present? && code == 401
      Rails.logger.warn('[Captain::ToolsManifest] CAPTAIN_TOOLS_GITHUB_TOKEN was rejected by GitHub, retrying without it')
      code, body = get(url, headers)
    end
    body!(code, body, url)
  end

  def fetch(url)
    body!(*get(url), url)
  end

  # Only GitHub's own hosts are requested and path segments are validated, so SafeFetch's SSRF checks aren't needed.
  # The body is streamed so an oversized file is abandoned at the manifest limit instead of loaded into memory.
  def get(url, headers = {})
    body = +''
    response = HTTParty.get(url, headers: headers, timeout: REQUEST_TIMEOUT, stream_body: true) do |fragment|
      # Redirects stream their own fragments; only the final response's body is kept
      next unless fragment.code == 200

      body << fragment
      raise SourceError, "#{url} is larger than 256 KiB" if body.bytesize > Captain::ToolsManifest::Validator::MAX_BYTES
    end
    [response.code, body]
  rescue HTTParty::Error, SocketError, Timeout::Error, SystemCallError, OpenSSL::SSL::SSLError => e
    raise SourceError, "Could not fetch #{url}: #{e.message}"
  end

  def body!(code, body, url)
    raise SourceError, "Could not fetch #{url}: #{code}" unless (200..299).cover?(code)

    body
  end
end
