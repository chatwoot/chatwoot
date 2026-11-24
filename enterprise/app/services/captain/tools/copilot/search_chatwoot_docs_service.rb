# Searches Chatwoot's public user guide, a help center portal whose base URL Super Admin sets in CAPTAIN_CHATWOOT_DOCS_URL.
# Only the query text comes from the model. The host and path come from the config, and an article is fetched only
# when the search returned a link inside the configured portal.
class Captain::Tools::Copilot::SearchChatwootDocsService < Captain::Tools::BaseTool
  CONFIG_KEY = 'CAPTAIN_CHATWOOT_DOCS_URL'.freeze
  # The search ranks by matching words, so the right article is sometimes fourth or fifth.
  MAX_ARTICLES = 5
  # Long enough for the longest user guide articles, whose plan and comparison tables often sit near the end.
  MAX_ARTICLE_CHARACTERS = 15_000
  # One limit for the whole search. Most help center searches answer within a second, but in a week of production logs
  # about 1 in 100 took 13 to 15 seconds.
  SEARCH_TIMEOUT = 20
  UNREACHABLE_MESSAGE = 'Could not reach the Chatwoot docs.'.freeze
  HTTP_ERRORS = [HTTParty::Error, SocketError, Timeout::Error, SystemCallError, OpenSSL::SSL::SSLError, URI::InvalidURIError,
                 JSON::ParserError].freeze

  class RequestError < StandardError; end

  def self.name
    'search_chatwoot_docs'
  end

  description "Search Chatwoot's product documentation for how Chatwoot features, settings, channels and plans work. " \
              'Returns the closest articles with their links, even when none of them covers the question.'
  parameter :query, type: :string, description: 'What the agent wants to know about using Chatwoot', required: true

  def execute(query:)
    Timeout.timeout(SEARCH_TIMEOUT) { docs_text(query) }
  rescue RequestError, *HTTP_ERRORS => e
    Rails.logger.error("[Captain::Copilot] search_chatwoot_docs failed for #{base_url}: #{e.class}: #{e.message}")
    # An error result marks the step as failed in the panel, and the model still reads the message.
    { error: UNREACHABLE_MESSAGE }
  end

  def active?
    base_url.present?
  end

  private

  # Articles outside the configured portal are dropped before the cut, so they never take the place of one that can be read.
  def docs_text(query)
    articles = search_results(query).select { |article| article_slug(article['link']) }.first(MAX_ARTICLES)
    return 'The Chatwoot docs returned no articles.' if articles.empty?

    articles.map { |article| article_text(article) }.join("\n---\n")
  end

  def base_url
    @base_url ||= GlobalConfig.get_value(CONFIG_KEY).to_s.strip.delete_suffix('/')
  end

  # The account's own locale first, then the portal's default locale, alternating so both languages appear in the top results.
  def search_results(query)
    locales = [@assistant.account.locale, default_locale].compact_blank.uniq
    result_lists = locales.map { |locale| search(locale, query) }
    longest = result_lists.map(&:size).max
    Array.new(longest) { |index| result_lists.map { |list| list[index] } }.flatten.compact.uniq { |article| article['link'] }
  end

  def default_locale
    get_json("#{base_url}/#{ERB::Util.url_encode(@assistant.account.locale)}.json").dig('meta', 'default_locale')
  end

  def search(locale, query)
    get_json("#{base_url}/#{ERB::Util.url_encode(locale)}/articles.json", query: { query: query }).fetch('payload', [])
  end

  def article_text(article)
    url = "#{base_url}/articles/#{ERB::Util.url_encode(article_slug(article['link']))}"
    body = get("#{url}.md").to_s.truncate(MAX_ARTICLE_CHARACTERS, separator: ' ')
    "Title: #{article['title']}\nURL: #{url}\n\n#{body}"
  end

  # The search returns links such as /hc/<portal>/articles/<slug>. Anything outside the configured portal is not fetched.
  def article_slug(link)
    prefix = "#{URI.parse(base_url).path}/articles/"
    return unless link.to_s.start_with?(prefix)

    slug = CGI.unescape(link.delete_prefix(prefix))
    slug if slug.present? && slug.exclude?('/') && slug != '..'
  end

  def get_json(url, query: nil)
    JSON.parse(get(url, query: query))
  end

  def get(url, query: nil)
    # Net::HTTP retries a timed out GET once by default, and the help center keeps running the first search.
    response = HTTParty.get(url, query: query, timeout: SEARCH_TIMEOUT, max_retries: 0, follow_redirects: false)
    raise RequestError, "#{url} returned #{response.code}" unless response.success?

    response.body
  end
end
