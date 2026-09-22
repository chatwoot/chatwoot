class Enterprise::LoginLocationNotificationJob < ApplicationJob
  queue_as :low

  # Cap on distinct prior IPs resolved, so a long-lived account does not resolve
  # thousands of addresses. Deduplicated first, so multi-account sign-in rows
  # (one per account) do not eat into the cap.
  DISTINCT_IP_LIMIT = 50

  # device is the controller's RequestDeviceInfo capture ({ ip:, browser_name:, platform_name: }),
  # so mobile-app sign-ins keep their X-Chatwoot-* device labels.
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

    seen = seen_countries(lookup, user_id, before_audit_id)
    return if seen.blank? || seen.include?(result.country)

    { city: result.city, country: result.country, ip: remote_address }
  end

  # Most-recent distinct prior sign-in IPs, resolved to countries. History is
  # bounded to audit rows inserted strictly before the current sign-in's own
  # rows (id < before_audit_id). Excluding only the current request_uuid would
  # let two concurrent sign-ins from the same new country each see the other's
  # row and both stay silent; with the id bound the earlier-inserted sign-in
  # cannot see the later one, so at least one alert always fires.
  def seen_countries(lookup, user_id, before_audit_id)
    scope = Enterprise::AuditLog.where(user_id: user_id, action: 'sign_in').where.not(remote_address: nil)
    scope = scope.where(id: ...before_audit_id) if before_audit_id.present?

    scope.group(:remote_address)
         .order(Arel.sql('MAX(created_at) DESC'))
         .limit(DISTINCT_IP_LIMIT)
         .pluck(:remote_address)
         .filter_map { |ip| lookup.perform(ip)&.country }
         .uniq
  end
end
