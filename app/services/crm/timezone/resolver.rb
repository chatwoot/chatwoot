# Central, fail-closed timezone resolver for CRM scheduling paths.
# Precedence: explicit -> contact.additional_attributes['timezone'] ->
# account.reporting_timezone -> (none valid) nil / raise. UTC is NEVER a
# silent fallback; only used if a caller passes 'UTC' explicitly.
class Crm::Timezone::Resolver
  Unresolvable = Class.new(StandardError)

  def initialize(explicit: nil, contact: nil, account: nil)
    @explicit = explicit
    @contact = contact
    @account = account
  end

  def name
    candidates.each do |raw|
      candidate = raw.to_s.strip
      next if candidate.blank?
      return candidate if ActiveSupport::TimeZone[candidate].present?
    end
    nil
  end

  def name!
    name || raise(Unresolvable, 'no valid CRM timezone (explicit, contact, account all missing/invalid)')
  end

  def zone
    resolved = name
    resolved && ActiveSupport::TimeZone[resolved]
  end

  def zone!
    ActiveSupport::TimeZone[name!]
  end

  private

  def candidates
    [@explicit, contact_timezone, account_timezone]
  end

  def contact_timezone
    @contact&.additional_attributes.to_h['timezone']
  end

  def account_timezone
    @account.try(:reporting_timezone)
  end
end
