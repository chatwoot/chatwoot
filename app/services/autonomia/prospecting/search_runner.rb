require 'digest'

class Autonomia::Prospecting::SearchRunner
  Result = Struct.new(:search, :leads, keyword_init: true)

  class UnsupportedProviderError < StandardError; end
  class ProviderError < StandardError; end

  def initialize(account:, user:, params:)
    @account = account
    @user = user
    @params = params.to_h.symbolize_keys
    @setting = Autonomia::Prospecting::Setting.for_account(account)
  end

  def perform
    validate!
    cached = cached_result
    return cached if cached
    validate_usage_limits!

    search = create_search!
    leads = []

    ActiveRecord::Base.transaction do
      provider_instance = provider
      leads = provider_instance.search.map { |attributes| upsert_lead!(search, attributes) }
      search.metadata = search.metadata.to_h.merge(
        'lead_ids' => leads.map(&:id),
        'results_count' => leads.size
      )
      search.status = :completed
      search.consumed_api_units = provider_instance.respond_to?(:api_units) ? provider_instance.api_units.to_i : 0
      search.cache_fingerprint = cache_fingerprint
      search.cache_expires_at = cache_expires_at
      search.save!
    end

    Result.new(search: search.reload, leads: leads)
  rescue StandardError => e
    search&.update!(status: :failed, metadata: search.metadata.to_h.merge('error' => e.message)) if search&.persisted?
    raise
  end

  private

  def validate!
    raise ActiveRecord::RecordInvalid.new(search_with_error(:query, "can't be blank")) if query.blank?
    raise UnsupportedProviderError, 'Unsupported prospecting provider' unless %w[mock google_places].include?(provider_name)
    raise ActiveRecord::RecordInvalid.new(search_with_error(:requested_limit, 'must be greater than 0')) if requested_limit <= 0
    validate_google_places! if provider_name == 'google_places'

    return if requested_limit <= @setting.max_results_per_search

    raise ActiveRecord::RecordInvalid.new(
      search_with_error(:requested_limit, "must be less than or equal to #{@setting.max_results_per_search}")
    )
  end

  def create_search!
    Autonomia::Prospecting::Search.create!(
      account: @account,
      user: @user,
      query: query,
      location: location,
      radius: radius,
      provider: provider_name,
      requested_limit: requested_limit,
      status: :pending,
      cache_fingerprint: cache_fingerprint,
      cache_expires_at: cache_expires_at,
      categories: categories,
      metadata: metadata.merge(crm_target_metadata)
    )
  end

  def provider
    case provider_name
    when 'google_places'
      Autonomia::Prospecting::Providers::GooglePlacesProvider.new(
        query: query,
        location: location,
        radius: radius,
        limit: requested_limit,
        api_key: @setting.google_places_api_key
      )
    else
      Autonomia::Prospecting::Providers::MockProvider.new(
        query: query,
        location: location,
        radius: radius,
        limit: requested_limit
      )
    end
  end

  def validate_google_places!
    raise ProviderError, 'Google Places provider is disabled for this account' unless @setting.provider_enabled?
    raise ProviderError, 'Google Places API key is not configured for this account' unless @setting.google_places_configured?
  end

  def upsert_lead!(search, attributes)
    dedupe_key = dedupe_key_for(attributes)
    lead = find_existing_lead(attributes, dedupe_key) || Autonomia::Prospecting::Lead.new(account: @account)
    lead.assign_attributes(attributes.merge(search: search, dedupe_key: dedupe_key))
    lead.save!
    lead
  end

  def find_existing_lead(attributes, dedupe_key)
    scope = Autonomia::Prospecting::Lead.where(account: @account)

    if attributes[:provider_place_id].present?
      existing = scope.find_by(provider: attributes[:provider], provider_place_id: attributes[:provider_place_id])
      return existing if existing
    end

    scope.find_by(dedupe_key: dedupe_key)
  end

  def dedupe_key_for(attributes)
    [
      attributes[:provider],
      attributes[:provider_place_id].presence ||
        attributes[:phone].presence ||
        attributes[:website].presence ||
        attributes[:name]
    ].join(':').downcase
  end

  def query
    @query ||= @params[:query].to_s.strip
  end

  def location
    @location ||= @params[:location].to_s.strip
  end

  def radius
    @radius ||= @params[:radius].presence&.to_i || 5000
  end

  def provider_name
    @provider_name ||= @setting.provider.presence || 'mock'
  end

  def requested_limit
    @requested_limit ||= (@params[:requested_limit].presence || @params[:limit].presence || @setting.default_limit).to_i
  end

  def categories
    Array(@params[:categories]).compact_blank
  end

  def metadata
    @params[:metadata].presence || {}
  end

  def crm_target_metadata
    {
      'crm_pipeline_id' => crm_pipeline_id,
      'crm_stage_id' => crm_stage_id
    }.compact
  end

  def cached_result
    return if @setting.cache_ttl_seconds.to_i <= 0

    search = Autonomia::Prospecting::Search
             .where(account: @account, provider: provider_name, cache_fingerprint: cache_fingerprint)
             .where('cache_expires_at > ?', Time.current)
             .order(created_at: :desc)
             .first
    return if search.blank?

    lead_ids = Array(search.metadata.to_h['lead_ids']).map(&:to_i)
    leads = Autonomia::Prospecting::Lead.where(account: @account, id: lead_ids).index_by(&:id).values_at(*lead_ids).compact
    cached_search = Autonomia::Prospecting::Search.create!(
      account: @account,
      user: @user,
      query: query,
      location: location,
      radius: radius,
      provider: provider_name,
      requested_limit: requested_limit,
      status: :cached,
      consumed_api_units: 0,
      cache_fingerprint: cache_fingerprint,
      cache_expires_at: search.cache_expires_at,
      categories: categories,
      metadata: metadata.merge(crm_target_metadata).merge(
        'lead_ids' => leads.map(&:id),
        'results_count' => leads.size,
        'cached_from_search_id' => search.id
      )
    )

    Result.new(search: cached_search, leads: leads)
  end

  def cache_fingerprint
    @cache_fingerprint ||= Digest::SHA256.hexdigest(
      [@account.id, provider_name, query.downcase, location.downcase, radius, requested_limit].join(':')
    )
  end

  def cache_expires_at
    return if @setting.cache_ttl_seconds.to_i <= 0

    Time.current + @setting.cache_ttl_seconds.to_i.seconds
  end

  def search_with_error(attribute, message)
    search = Autonomia::Prospecting::Search.new
    search.errors.add(attribute, message)
    search
  end

  def validate_usage_limits!
    return if estimated_api_units.zero?

    validate_usage_limit!(:daily_limit, Time.current.beginning_of_day)
    validate_usage_limit!(:monthly_limit, Time.current.beginning_of_month)
  end

  def validate_usage_limit!(limit_attribute, period_start)
    limit = @setting.public_send(limit_attribute).to_i
    return if limit <= 0

    usage = Autonomia::Prospecting::Search
            .where(account: @account)
            .where('created_at >= ?', period_start)
            .sum(:consumed_api_units)
    return if usage + estimated_api_units <= limit

    raise ProviderError, "#{limit_attribute.to_s.humanize} exceeded for prospecting"
  end

  def estimated_api_units
    @estimated_api_units ||= provider_name == 'google_places' ? 1 : 0
  end

  def crm_pipeline_id
    @crm_pipeline_id ||= @params[:crm_pipeline_id].presence || @setting.default_crm_pipeline_id
  end

  def crm_stage_id
    @crm_stage_id ||= @params[:crm_stage_id].presence || @setting.default_crm_stage_id
  end
end
