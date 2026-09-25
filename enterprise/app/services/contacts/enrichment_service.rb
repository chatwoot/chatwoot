# Enriches a contact profile from Context.dev's person enrichment using the identity clues
# we already have: a work email, a LinkedIn profile, or a full name with a company.
# By default only blank fields are filled; `overwrite: true` replaces them with fresh data.
# The contact's name is never overwritten, since agents often correct it by hand.
class Contacts::EnrichmentService
  ENDPOINT = 'https://api.context.dev/v1/people/enrich'.freeze
  TIMEOUT_MS = 25_000
  # Context.dev returns its best candidate even for weak matches; below this we'd risk
  # filling a profile with someone else's details.
  MIN_MATCH_SCORE = 70
  # Contacts store social profiles as handles, rendered with a per-network URL prefix.
  SOCIAL_HOSTS = {
    'linkedin.com' => 'linkedin',
    'x.com' => 'twitter',
    'twitter.com' => 'twitter',
    'github.com' => 'github',
    'facebook.com' => 'facebook',
    'instagram.com' => 'instagram',
    'tiktok.com' => 'tiktok'
  }.freeze

  def self.enabled?
    GlobalConfigService.load('CONTEXT_DEV_API_KEY', nil).present?
  end

  def initialize(contact, overwrite: false)
    @contact = contact
    @overwrite = overwrite
  end

  def identity_clues
    @identity_clues ||= {
      email: (@contact.email if Companies::BusinessEmailDetectorService.new(@contact.email).perform),
      social_urls: linkedin_url && [linkedin_url],
      **name_with_company_clues
    }.compact
  end

  def perform
    person = fetch_person
    return if person.blank?

    @contact.name = person.dig('name', 'full') if @contact.name.blank? && person.dig('name', 'full').present?
    @contact.additional_attributes = merge_attributes(enriched_attributes(person))
    @contact.additional_attributes['enriched_at'] = Time.current.iso8601
    @contact.save!
    attach_avatar(person['avatar_url'])
    @contact
  end

  private

  def fetch_person
    response = HTTParty.post(
      ENDPOINT,
      body: identity_clues.merge(timeoutOpts: { milliseconds: TIMEOUT_MS, behavior: 'return-partial' }).to_json,
      headers: { 'Authorization' => "Bearer #{GlobalConfigService.load('CONTEXT_DEV_API_KEY', nil)}", 'Content-Type' => 'application/json' },
      timeout: (TIMEOUT_MS / 1000) + 5
    )
    unless response.success?
      Rails.logger.warn "[ContactEnrichment] Context.dev returned #{response.code} for contact=#{@contact.id}"
      return
    end

    match = response.parsed_response['match'] || {}
    match['person'] if match['status'] == 'candidate' && match['score'].to_i >= MIN_MATCH_SCORE
  end

  def enriched_attributes(person)
    role = person['current_role'] || {}
    location = person['location'] || {}

    {
      'description' => person['bio'],
      'job_title' => role['title'],
      'company_name' => role.dig('organization', 'name'),
      'city' => location['city'],
      'country' => location['country'],
      'country_code' => location['country_code']&.upcase,
      'social_profiles' => social_profiles(person['social_urls'])
    }.compact_blank
  end

  def social_profiles(urls)
    Array(urls).each_with_object({}) do |url, profiles|
      uri = URI.parse(url)
      network = SOCIAL_HOSTS[uri.host.to_s.delete_prefix('www.')]
      handle = uri.path.delete_prefix('/').delete_suffix('/').delete_prefix('@')
      profiles[network] = handle if network && handle.present?
    rescue URI::InvalidURIError
      next
    end
  end

  def merge_attributes(attributes)
    existing_attributes = @contact.additional_attributes || {}
    social_profiles = merge_values(existing_attributes['social_profiles'] || {}, attributes.delete('social_profiles') || {})
    # A contact linked to a company keeps its name in sync with that company.
    attributes.delete('company_name') if @contact.company_id.present?
    merge_values(existing_attributes, attributes).merge({ 'social_profiles' => social_profiles }.compact_blank)
  end

  def merge_values(existing, fresh)
    existing.merge(fresh) do |_key, current, value|
      @overwrite ? value : current.presence || value
    end
  end

  def attach_avatar(avatar_url)
    return if avatar_url.blank?
    return if @contact.avatar.attached? && !@overwrite

    Avatar::AvatarFromUrlJob.perform_later(@contact, avatar_url)
  end

  def linkedin_url
    handle = @contact.additional_attributes&.dig('social_profiles', 'linkedin')
    return if handle.blank?

    return handle if handle.start_with?('http')

    # Handles are usually saved as `in/<name>`, but a bare `<name>` is a personal profile too.
    path = handle.delete_prefix('/')
    "https://www.linkedin.com/#{path.include?('/') ? path : "in/#{path}"}"
  end

  def name_with_company_clues
    first, last = @contact.name.to_s.strip.split(/\s+/, 2)
    company = {
      name: @contact.company&.name || @contact.additional_attributes&.dig('company_name'),
      domain: @contact.company&.domain
    }.compact_blank
    return {} if last.blank? || company.blank?

    { name: { first: first, last: last }, company: company }
  end
end
