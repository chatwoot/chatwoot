require 'digest'
require 'json'

class Autonomia::Prospecting::SearchRunner
  AREA_TYPES = %w[radius viewport].freeze

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
      leads = provider_instance.search.each_with_index.map do |attributes, index|
        upsert_lead!(search, attributes, google_rank: index + 1)
      end
      assign_priority_positions!(leads)
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
      area_type: area_type,
      area_config: area_config,
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
        area_type: area_type,
        area_config: area_config,
        limit: requested_limit,
        api_key: @setting.google_places_api_key
      )
    else
      Autonomia::Prospecting::Providers::MockProvider.new(
        query: query,
        location: location,
        radius: radius,
        area_type: area_type,
        area_config: area_config,
        limit: requested_limit
      )
    end
  end

  def validate_google_places!
    raise ProviderError, 'Google Places provider is disabled for this account' unless @setting.provider_enabled?
    raise ProviderError, 'Google Places API key is not configured for this account' unless @setting.google_places_configured?
  end

  def upsert_lead!(search, attributes, google_rank:)
    dedupe_key = dedupe_key_for(attributes)
    lead = find_existing_lead(attributes, dedupe_key) || Autonomia::Prospecting::Lead.new(account: @account)
    scoring_attributes = score_for(attributes, google_rank)
    lead.assign_attributes(
      attributes.merge(scoring_attributes).merge(search: search, dedupe_key: dedupe_key, search_rank: google_rank)
    )
    lead.save!
    lead
  end

  def score_for(attributes, google_rank)
    Autonomia::Prospecting::LeadScorer.new(
      lead_attributes: attributes,
      query: query,
      google_rank: google_rank,
      weights: @setting.active_scoring_weights
    ).perform
  end

  def assign_priority_positions!(leads)
    leads.compact
         .sort_by { |lead| [-lead.priority_score.to_f, lead.name.to_s] }
         .each_with_index do |lead, index|
           lead.update_column(:priority_position, index + 1)
         end
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

  def area_type
    @area_type ||= begin
      requested_type = @params[:area_type].to_s
      AREA_TYPES.include?(requested_type) ? requested_type : 'radius'
    end
  end

  def area_config
    @area_config ||= normalized_area_config
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
    @metadata ||= begin
      raw_metadata = @params[:metadata].presence || {}
      raw_metadata = raw_metadata.to_unsafe_h if raw_metadata.respond_to?(:to_unsafe_h)
      raw_metadata = raw_metadata.to_h if raw_metadata.respond_to?(:to_h)
      raw_metadata.deep_stringify_keys
    end
  end

  def normalized_area_config
    raw_config = @params[:area_config].presence || {}
    raw_config = raw_config.to_unsafe_h if raw_config.respond_to?(:to_unsafe_h)
    raw_config = raw_config.to_h if raw_config.respond_to?(:to_h)
    raw_config = raw_config.deep_stringify_keys

    center = normalize_center(raw_config['center']) || metadata_center
    base = {
      'label' => metadata['location_label'].presence || location.presence,
      'place_id' => metadata['location_place_id'].presence
    }.compact

    if area_type == 'viewport'
      bounds = normalize_bounds(raw_config['bounds'])
      center ||= center_from_bounds(bounds)

      return base.merge(
        {
          'bounds' => bounds,
          'center' => center,
          'radius' => radius
        }.compact
      )
    end

    base.merge(
      {
        'center' => center,
        'radius' => radius
      }.compact
    )
  end

  def metadata_center
    lat = metadata['location_latitude'].presence
    lng = metadata['location_longitude'].presence
    normalize_center('lat' => lat, 'lng' => lng)
  end

  def normalize_center(value)
    return if value.blank?

    hash = value.respond_to?(:to_h) ? value.to_h.deep_stringify_keys : {}
    lat = numeric_value(hash['lat'] || hash['latitude'])
    lng = numeric_value(hash['lng'] || hash['longitude'])
    return if lat.nil? || lng.nil?

    { 'lat' => lat, 'lng' => lng }
  end

  def normalize_bounds(value)
    return if value.blank?

    hash = value.respond_to?(:to_h) ? value.to_h.deep_stringify_keys : {}
    north = numeric_value(hash['north'])
    south = numeric_value(hash['south'])
    east = numeric_value(hash['east'])
    west = numeric_value(hash['west'])
    return if [north, south, east, west].any?(&:nil?)

    {
      'north' => [north, south].max,
      'south' => [north, south].min,
      'east' => east,
      'west' => west
    }
  end

  def center_from_bounds(bounds)
    return if bounds.blank?

    {
      'lat' => ((bounds['north'].to_f + bounds['south'].to_f) / 2.0).round(6),
      'lng' => ((bounds['east'].to_f + bounds['west'].to_f) / 2.0).round(6)
    }
  end

  def numeric_value(value)
    return if value.blank?

    Float(value).round(6)
  rescue ArgumentError, TypeError
    nil
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
      area_type: area_type,
      area_config: area_config,
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
      [
        @account.id,
        provider_name,
        query.downcase,
        location.downcase,
        radius,
        area_type,
        JSON.generate(area_config),
        requested_limit,
        @setting.scoring_mode,
        @setting.scoring_profile_id,
        @setting.active_scoring_weights.sort.to_h
      ].join(':')
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
