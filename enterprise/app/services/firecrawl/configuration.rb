module Firecrawl::Configuration
  INSTALLATION_CONFIG_KEY = 'CAPTAIN_FIRECRAWL_API_KEY'.freeze
  BASE_URL_CONFIG_KEY = 'CAPTAIN_FIRECRAWL_BASE_URL'.freeze
  DEFAULT_BASE_URL = 'https://api.firecrawl.dev'.freeze
  EXCLUDE_TAGS = %w[iframe .sidebar .cookie-banner [role=navigation] [role=banner] [role=contentinfo]].freeze
  DEFAULT_SCRAPE_MAX_AGE_MS = 7 * 24 * 60 * 60 * 1000

  module_function

  def configured?
    api_key.present?
  end

  def client
    key = api_key
    raise ::Firecrawl::FirecrawlError, "#{INSTALLATION_CONFIG_KEY} is not configured" if key.blank?

    ::Firecrawl::Client.new(api_key: key, api_url: api_url)
  end

  def api_key
    InstallationConfig.find_by(name: INSTALLATION_CONFIG_KEY)&.value
  end

  def base_url
    InstallationConfig.find_by(name: BASE_URL_CONFIG_KEY)&.value.presence || DEFAULT_BASE_URL
  end

  def api_url
    normalized_base_url.sub(%r{/v2\z}, '')
  end

  def v2_base_url
    url = normalized_base_url
    url.end_with?('/v2') ? url : "#{url}/v2"
  end

  def normalized_base_url
    base_url.strip.chomp('/')
  end

  def default_scrape_options(max_age: DEFAULT_SCRAPE_MAX_AGE_MS)
    ::Firecrawl::Models::ScrapeOptions.new(
      formats: ['markdown'],
      only_main_content: true,
      exclude_tags: EXCLUDE_TAGS,
      max_age: max_age
    )
  end
end
