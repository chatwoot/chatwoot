# A toolset folder in a public GitHub repository, addressed as owner/repository/folder.
class Captain::ToolsManifest::GithubSource
  class SourceError < StandardError; end

  INVALID_SOURCE_MESSAGE = 'Source must be owner/repository/folder'.freeze
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

    owner, repository, @folder = parse(source.strip)
    raise SourceError, INVALID_SOURCE_MESSAGE unless [owner, repository, @folder].all? { |segment| valid_segment?(segment) }

    # GitHub ignores case in owner and repository names, so the stored identity is lowercase to avoid
    # duplicate installs. Folder names are case-sensitive on GitHub, so downloads keep the folder as typed.
    @repository = "#{owner}/#{repository}".downcase
    @path = @folder.downcase
  end

  def latest_revision
    revision = github_api("/repos/#{repository}/commits/HEAD", accept: 'application/vnd.github.sha').strip
    raise SourceError, "Could not resolve the latest commit of #{repository}" unless REVISION_PATTERN.match?(revision)

    revision
  end

  def manifest(revision)
    fetch("#{RAW_URL}/#{repository}/#{revision}/#{@folder}/#{MANIFEST_FILE}")
  end

  private

  def parse(source)
    parts = source.split('/', -1)
    parts.size == 3 ? parts : []
  end

  def valid_segment?(segment)
    segment.to_s.match?(SEGMENT_PATTERN) && !segment.match?(DOT_SEGMENT_PATTERN)
  end

  # The token only raises the GitHub API rate limit, so an expired or revoked one falls back to an unauthenticated request
  def github_api(path, accept:)
    url = "#{API_URL}#{path}"
    headers = { 'Accept' => accept }
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
    raise SourceError, "Could not fetch #{url}: #{e.message}"
  end

  def body!(response, url)
    raise SourceError, "Could not fetch #{url}: #{response.code}" unless response.success?

    response.body
  end
end
