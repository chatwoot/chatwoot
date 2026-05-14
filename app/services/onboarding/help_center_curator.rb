class Onboarding::HelpCenterCurator
  MAP_LIMIT = 500
  MAP_SEARCH = 'docs help support faq'.freeze
  MIN_ARTICLES = 3

  Skipped = CustomExceptions::HelpCenter::CurationSkipped

  def initialize(account:, portal:)
    @account = account
    @portal = portal
  end

  def perform
    raise Skipped, 'Firecrawl not configured' unless Firecrawl::Configuration.configured?
    raise Skipped, 'no website url' if website_url.blank?

    links = discover_links
    raise Skipped, 'map returned no links' if links.empty?

    plan = curate(links)
    raise Skipped, "only #{plan[:articles].size} articles curated (< #{MIN_ARTICLES} threshold)" if plan[:articles].size < MIN_ARTICLES

    plan.merge(allowed_urls: extract_urls(links)).deep_stringify_keys
  end

  private

  def discover_links
    data = Firecrawl::Configuration.client.map(
      website_url,
      Firecrawl::Models::MapOptions.new(limit: MAP_LIMIT, search: MAP_SEARCH)
    )
    Array(data.links)
  end

  def extract_urls(links)
    # Firecrawl's MapData normalises every link to a string-keyed hash
    # ({ "url" => ... }), so read both keys to stay tolerant of either shape.
    Array(links).filter_map do |link|
      raw = link.is_a?(Hash) ? (link['url'] || link[:url]) : link
      raw.to_s.presence
    end.uniq
  end

  def curate(links)
    response = Captain::Llm::HelpCenterCurationService.new(account: @account, links: links).perform
    raise Skipped, "curator LLM error: #{response[:error]}" if response[:error]

    response[:message] || { categories: [], articles: [] }
  end

  def website_url
    @website_url ||= with_scheme(custom_attributes_website.presence || brand_info[:domain].presence)
  end

  def with_scheme(raw)
    return raw if raw.blank?

    raw.match?(%r{\Ahttps?://}i) ? raw : "https://#{raw}"
  end

  def custom_attributes_website
    @account.custom_attributes['website']
  end

  def brand_info
    @brand_info ||= (@account.custom_attributes['brand_info'] || {}).deep_symbolize_keys
  end
end
