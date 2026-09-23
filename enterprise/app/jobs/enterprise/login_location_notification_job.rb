class Enterprise::LoginLocationNotificationJob < ApplicationJob
  queue_as :low

  # Cap on distinct prior IPs resolved, so a long-lived account does not resolve
  # thousands of addresses. Deduplicated first, so multi-account sign-in rows
  # (one per account) do not eat into the cap.
  DISTINCT_IP_LIMIT = 50

  # Older history must not vouch for a location: it may include an unnoticed compromise.
  HISTORY_WINDOW = 90.days

  # device: RequestDeviceInfo capture from the controller ({ ip:, browser_name:, platform_name: })
  def perform(user_id, recipient_email, device, before_audit_id)
    return unless LoginLocationNotification.enabled?

    device = device.to_h.symbolize_keys
    return if recipient_email.blank? || device[:ip].blank?

    meta = new_location_meta(user_id, device[:ip], before_audit_id)
    return unless meta

    Enterprise::LoginLocationMailer.new_location(meta.merge(device).merge(email: recipient_email)).deliver_later
  end

  private

  # Returns the location meta when the sign-in is from a new country, otherwise nil.
  def new_location_meta(user_id, remote_address, before_audit_id)
    lookup = IpLookupService.new
    result = lookup.perform(remote_address)
    return if result&.country.blank?

    return unless location_unrecognized?(lookup, user_id, before_audit_id, result.country)

    { city: result.city, country: result.country, ip: remote_address }
  end

  # Empty window: quiet on a first-ever sign-in, alert on a dormant account returning
  # (nothing recent vouches for any location).
  def location_unrecognized?(lookup, user_id, before_audit_id, country)
    scope = prior_sign_ins(user_id, before_audit_id)
    seen = recent_countries(lookup, scope)
    return seen.exclude?(country) if seen.present?

    scope.exists?
  end

  # id-bounded so concurrent sign-ins cannot vouch for each other; at least one of two
  # racing sign-ins from a new country always alerts.
  def prior_sign_ins(user_id, before_audit_id)
    scope = Enterprise::AuditLog.where(user_id: user_id, action: 'sign_in').where.not(remote_address: nil)
    scope = scope.where(id: ...before_audit_id) if before_audit_id.present?
    scope
  end

  def recent_countries(lookup, scope)
    scope.where(created_at: HISTORY_WINDOW.ago..)
         .group(:remote_address)
         .order(Arel.sql('MAX(created_at) DESC'))
         .limit(DISTINCT_IP_LIMIT)
         .pluck(:remote_address)
         .filter_map { |ip| lookup.perform(ip)&.country }
         .uniq
  end
end
