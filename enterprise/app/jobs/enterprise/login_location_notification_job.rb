class Enterprise::LoginLocationNotificationJob < ApplicationJob
  queue_as :low

  # Cap on distinct prior IPs resolved, so a long-lived account does not resolve
  # thousands of addresses. Deduplicated first, so multi-account sign-in rows
  # (one per account) do not eat into the cap.
  DISTINCT_IP_LIMIT = 50

  def perform(user_id, recipient_email, remote_address, user_agent, request_uuid)
    return unless LoginLocationNotification.enabled?
    return if recipient_email.blank? || remote_address.blank?

    meta = new_location_meta(user_id, remote_address, user_agent, request_uuid)
    return unless meta

    Enterprise::LoginLocationMailer.new_location(meta.merge(email: recipient_email)).deliver_later
  end

  private

  # Returns the mailer meta when the sign-in is from a new country, otherwise nil.
  def new_location_meta(user_id, remote_address, user_agent, request_uuid)
    lookup = IpLookupService.new
    result = lookup.perform(remote_address)
    return if result&.country.blank?

    seen = seen_countries(lookup, user_id, request_uuid)
    return if seen.blank? || seen.include?(result.country)

    browser = Browser.new(user_agent.to_s)
    { city: result.city, country: result.country, ip: remote_address,
      browser_name: browser.name, platform_name: browser.platform.name }
  end

  # Most-recent distinct prior sign-in IPs, resolved to countries. The current
  # sign-in is excluded by request_uuid (timestamps are unreliable across the
  # sub-second gap between the audit insert and this job).
  def seen_countries(lookup, user_id, request_uuid)
    scope = Enterprise::AuditLog.where(user_id: user_id, action: 'sign_in').where.not(remote_address: nil)
    scope = scope.where.not(request_uuid: request_uuid) if request_uuid.present?

    scope.group(:remote_address)
         .order(Arel.sql('MAX(created_at) DESC'))
         .limit(DISTINCT_IP_LIMIT)
         .pluck(:remote_address)
         .filter_map { |ip| lookup.perform(ip)&.country }
         .uniq
  end
end
