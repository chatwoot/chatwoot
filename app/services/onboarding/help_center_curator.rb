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

    plan
  end

  private

  def discover_links
    data = Firecrawl::Configuration.client.map(
      website_url,
      Firecrawl::Models::MapOptions.new(limit: MAP_LIMIT, search: MAP_SEARCH)
    )
    Array(data.links)
  end

  def curate(links)
    response = Captain::Llm::HelpCenterCurationService.new(account: @account, links: links).perform
    raise Skipped, "curator LLM error: #{response[:error]}" if response[:error]

    response[:message] || { categories: [], articles: [] }
  end

  def website_url
    @website_url ||= custom_attributes_website.presence || @account.domain.presence || brand_info[:domain].presence
  end

  def custom_attributes_website
    @account.custom_attributes['website']
  end

  def brand_info
    @brand_info ||= (@account.custom_attributes['brand_info'] || {}).deep_symbolize_keys
  end
end
