# A toolset folder in the chatwoot/tools repository, addressed as chatwoot/tools/<folder>.
# Installs always use the latest commit on the default branch.
class Captain::ToolsManifest::GithubSource
  class SourceError < StandardError; end

  REPOSITORY = 'chatwoot/tools'.freeze
  INVALID_SOURCE_MESSAGE = "Enter a toolset from #{REPOSITORY} as #{REPOSITORY}/<folder>".freeze
  FOLDER_PATTERN = /\A[\w.-]+\z/
  DOT_SEGMENT_PATTERN = /\A\.+\z/
  REVISION_PATTERN = /\A[0-9a-f]{40}\z/
  MANIFEST_FILE = 'toolset.yml'.freeze
  MAX_BYTES = 256.kilobytes
  API_URL = 'https://api.github.com'.freeze
  RAW_URL = 'https://raw.githubusercontent.com'.freeze
  REQUEST_TIMEOUT = 10

  attr_reader :path

  def initialize(source)
    repository, _, @path = source.to_s.strip.rpartition('/')
    # GitHub ignores case in owner and repository names; folder names are case-sensitive, so the folder is kept as typed
    raise SourceError, INVALID_SOURCE_MESSAGE unless repository.casecmp?(REPOSITORY) && valid_folder?(@path)
  end

  def repository = REPOSITORY

  def latest_revision
    revision = github_api("/repos/#{repository}/commits/HEAD", accept: 'application/vnd.github.sha').strip
    raise SourceError, "Could not resolve the latest commit of #{repository}" unless REVISION_PATTERN.match?(revision)

    revision
  end

  def manifest(revision)
    fetch("#{RAW_URL}/#{repository}/#{revision}/#{path}/#{MANIFEST_FILE}")
  end

  private

  def valid_folder?(folder) = FOLDER_PATTERN.match?(folder) && !DOT_SEGMENT_PATTERN.match?(folder)

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

  # Only GitHub's own hosts are requested and the folder is validated, so SafeFetch's SSRF checks aren't needed.
  # The body is streamed so an oversized file is abandoned at the manifest limit instead of loaded into memory.
  def get(url, headers = {})
    body = +''
    response = HTTParty.get(url, headers: headers, timeout: REQUEST_TIMEOUT, stream_body: true) do |fragment|
      # Redirects stream their own fragments; only the final response's body is kept
      next unless fragment.code == 200

      body << fragment
      raise SourceError, "#{url} is larger than 256 KiB" if body.bytesize > MAX_BYTES
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
