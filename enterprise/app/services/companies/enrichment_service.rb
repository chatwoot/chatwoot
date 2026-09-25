# Enriches a company profile from Context.dev using its domain.
# By default only blank fields are filled; `overwrite: true` replaces them with fresh data.
class Companies::EnrichmentService
  ENDPOINT = 'https://api.context.dev/v1/brand/retrieve'.freeze
  TIMEOUT_MS = 25_000
  SOCIAL_PROFILE_TYPES = %w[linkedin x twitter facebook instagram github youtube].freeze

  def self.enabled?
    GlobalConfigService.load('CONTEXT_DEV_API_KEY', nil).present?
  end

  def self.enabled_for?(account)
    account.feature_enabled?('company_enrichment') && enabled?
  end

  def initialize(company, overwrite: false)
    @company = company
    @overwrite = overwrite
  end

  def perform
    brand = fetch_brand
    return if brand.blank?

    assign(:description, brand['description']&.truncate(Limits::COMPANY_DESCRIPTION_LENGTH_LIMIT))
    @company.additional_attributes = merge_attributes(enriched_attributes(brand))
    @company.additional_attributes['enriched_at'] = Time.current.iso8601
    @company.save!
    @company
  end

  private

  def fetch_brand
    response = HTTParty.post(
      ENDPOINT,
      body: { type: 'by_domain', domain: @company.domain, timeoutOpts: { milliseconds: TIMEOUT_MS, behavior: 'return-partial' } }.to_json,
      headers: { 'Authorization' => "Bearer #{GlobalConfigService.load('CONTEXT_DEV_API_KEY', nil)}", 'Content-Type' => 'application/json' },
      timeout: (TIMEOUT_MS / 1000) + 5
    )
    return response.parsed_response['brand'] if response.success?

    Rails.logger.warn "[CompanyEnrichment] Context.dev returned #{response.code} for company=#{@company.id}"
    nil
  end

  def enriched_attributes(brand)
    industry = brand.dig('industries', 'eic')&.first || {}
    address = brand['address'] || {}

    {
      'industry' => industry['industry'],
      'sub_industry' => industry['subindustry'],
      'employee_count_range' => brand.dig('employees', 'range'),
      'employee_count' => brand.dig('employees', 'exact'),
      'city' => address['city'],
      'country' => address['country'],
      'country_code' => address['country_code'],
      'phone' => brand['phone'],
      'social_profiles' => social_profiles(brand['socials'])
    }.compact_blank
  end

  def social_profiles(socials)
    Array(socials).each_with_object({}) do |social, profiles|
      profiles[social['type']] = social['url'] if SOCIAL_PROFILE_TYPES.include?(social['type']) && social['url'].present?
    end
  end

  def merge_attributes(attributes)
    @company.additional_attributes.merge(attributes) do |_key, existing, fresh|
      @overwrite ? fresh : existing.presence || fresh
    end
  end

  def assign(field, value)
    return if value.blank?
    return if @company[field].present? && !@overwrite

    @company[field] = value
  end
end
