class Influencers::SearchRegistry::FetchPageService
  COUNTRY_NAME_TO_CODE = {
    'Germany' => 'DE',
    'Poland' => 'PL',
    'France' => 'FR',
    'Netherlands' => 'NL',
    'United Kingdom' => 'GB',
    'Italy' => 'IT',
    'Spain' => 'ES',
    'Austria' => 'AT',
    'Belgium' => 'BE',
    'Denmark' => 'DK',
    'Sweden' => 'SE'
  }.freeze

  def initialize(account:, filter_params:, page:, discovery_service: nil)
    @account = account
    @filter_params = filter_params || {}
    @requested_page = [page.to_i, 1].max
    @discovery_service = discovery_service || InfluencersClub::DiscoveryService.new(account: account)
  end

  # rubocop:disable Metrics/MethodLength
  def perform
    search = find_or_initialize_search
    @page = clamp_page(search)
    cached = ensure_page_loaded(search)
    raw_results = search.page_results(@page)
    imported = 0

    profiles = raw_results.filter_map do |raw_result|
      profile, imported_profile = find_or_import_profile(raw_result)
      imported += 1 if imported_profile
      profile
    rescue StandardError => e
      Rails.logger.warn("Auto-import failed for search result: #{e.message}")
      nil
    end

    {
      search: search,
      profiles: profiles,
      meta: {
        total: search.results_count.to_i,
        credits_left: search.last_credits_left,
        imported: imported,
        current_page: @page,
        per_page: search.page_size,
        loaded_count: search.loaded_count,
        total_pages: total_pages(search),
        cached: cached
      }
    }
  end
  # rubocop:enable Metrics/MethodLength

  private

  # rubocop:disable Metrics/CyclomaticComplexity
  def find_or_initialize_search
    normalized_filters = normalizer.perform
    @account.influencer_searches.find_or_initialize_by(query_signature: normalizer.signature).tap do |search|
      search.query_params = normalized_filters
      search.page_size ||= page_size
      search.results ||= []
      search.results_count ||= 0
      search.pages_fetched ||= 0
      search.credits_used ||= 0
      search.save! if search.new_record? || search.changed?
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def ensure_page_loaded(search)
    return true if search.page_cached?(@page)

    cached = false
    search.with_lock do
      search.reload
      if search.page_cached?(@page)
        cached = true
        next
      end

      next_page = search.pages_fetched.to_i + 1
      response = @discovery_service.perform(
        filter_params: search.query_params.deep_symbolize_keys,
        paging: { limit: search.page_size, page: next_page }
      )
      merge_response!(search, response, next_page)
    end

    cached
  end

  def merge_response!(search, response, page_number)
    accounts = response.is_a?(Hash) ? Array(response['accounts']) : []
    search.append_page_results(accounts)
    search.results_count = response['total'] || search.results_count || accounts.size
    search.pages_fetched = page_number
    search.last_credits_left = response['credits_left'] if response.is_a?(Hash) && response.key?('credits_left')
    search.credits_used = search.credits_used.to_f + (accounts.size * 0.01)
    search.save!
  end

  def find_or_import_profile(raw_result)
    attrs = InfluencersClub::ResponseParser.parse_discovery_result(raw_result)
    return [nil, false] if attrs.blank? || attrs[:username].blank?

    existing_profile = @account.influencer_profiles.find_by(username: attrs[:username], platform: 'instagram')
    return [existing_profile, false] if existing_profile

    profile = Influencers::ImportService.new(
      account: @account,
      search_result: raw_result,
      target_market: target_market
    ).perform

    [profile, profile.present?]
  end

  # Only allow jumping one page beyond what's cached to avoid mass API calls
  def clamp_page(search)
    max_allowed = search.pages_fetched.to_i + 1
    [@requested_page, max_allowed].min
  end

  def target_market
    COUNTRY_NAME_TO_CODE[Array(@filter_params[:location] || @filter_params['location']).first]
  end

  def total_pages(search)
    return 0 if search.results_count.to_i.zero?

    (search.results_count.to_f / search.page_size).ceil
  end

  def page_size
    InfluencersClub::DiscoveryService::DEFAULT_PAGING[:limit]
  end

  def normalizer
    @normalizer ||= Influencers::SearchRegistry::FilterNormalizer.new(@filter_params)
  end
end
