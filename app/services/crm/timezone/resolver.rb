# Central timezone resolver for CRM scheduling paths.
# Precedence: explicit -> contact.additional_attributes['timezone'] ->
# contact single-timezone country -> account.reporting_timezone.
# When none resolves, #name_or_default falls back to a CONFIGURABLE last-resort
# default (ENV['CRM_DEFAULT_TIMEZONE'] when valid, else 'America/Sao_Paulo') so
# scheduling always anchors to a real local wall time instead of failing closed.
class Crm::Timezone::Resolver
  FALLBACK_TIMEZONE = 'America/Sao_Paulo'.freeze

  # Last-resort default: an explicitly configured, VALID tz name or São Paulo.
  # Never returns an invalid ActiveSupport::TimeZone name.
  def self.default_timezone
    configured = ENV['CRM_DEFAULT_TIMEZONE'].to_s.strip
    return configured if configured.present? && ActiveSupport::TimeZone[configured].present?

    FALLBACK_TIMEZONE
  end

  def initialize(explicit: nil, contact: nil, account: nil)
    @explicit = explicit
    @contact = contact
    @account = account
  end

  # First candidate that is a valid ActiveSupport::TimeZone, else nil.
  def name
    candidates.each do |raw|
      candidate = raw.to_s.strip
      next if candidate.blank?
      return candidate if ActiveSupport::TimeZone[candidate].present?
    end
    nil
  end

  # Always a valid tz name: the resolved candidate or the configurable default.
  def name_or_default
    name || self.class.default_timezone
  end

  def zone
    resolved = name
    resolved && ActiveSupport::TimeZone[resolved]
  end

  # Always a valid ActiveSupport::TimeZone (backed by name_or_default).
  def zone_or_default
    ActiveSupport::TimeZone[name_or_default]
  end

  private

  def candidates
    [@explicit, contact_additional_timezone, contact_country_timezone, account_timezone]
  end

  def contact_additional_timezone
    @contact&.additional_attributes.to_h['timezone']
  end

  # Exact only: a single-timezone country maps to its one zone. Multi-zone
  # countries (BR, US, ...) are AMBIGUOUS -> nil so we fall through to
  # account/default instead of guessing a wrong zone.
  #
  # Reads the ISO alpha-2 from additional_attributes['country_code'] (set by the
  # geocoder in ContactIpLookupJob). The contact.country_code DB column is NOT
  # used: Contacts::SyncAttributes populates it from additional_attributes['country'],
  # which is the country NAME ('Portugal'), not the ISO code.
  def contact_country_timezone
    country_code = @contact&.additional_attributes.to_h['country_code'].to_s.strip
    return unless country_code.match?(/\A[A-Za-z]{2}\z/)

    zones = zone_identifiers_for(country_code)
    zones.first if zones && zones.size == 1
  end

  def zone_identifiers_for(country_code)
    TZInfo::Country.get(country_code.to_s.upcase).zone_identifiers
  rescue TZInfo::InvalidCountryCode
    nil
  end

  def account_timezone
    @account.try(:reporting_timezone)
  end
end
