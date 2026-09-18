class Enterprise::LoginLocationNotificationJob < ApplicationJob
  queue_as :low

  # Cap how far back we look so a long-lived account does not resolve thousands of IPs.
  PRIOR_SIGN_IN_LIMIT = 100

  def perform(user_id, remote_address, user_agent, signed_in_at)
    return unless LoginLocationNotification.enabled?

    user = User.find_by(id: user_id)
    return unless user

    meta = new_location_meta(user_id, remote_address, user_agent, signed_in_at)
    return unless meta

    Enterprise::LoginLocationMailer.new_location(user, meta).deliver_later
  rescue StandardError => e
    Rails.logger.warn "Enterprise::LoginLocationNotificationJob failed: #{e.message}"
  end

  private

  # Returns the mailer meta when the sign-in is from a new country, otherwise nil.
  def new_location_meta(user_id, remote_address, user_agent, signed_in_at)
    return if remote_address.blank?

    lookup = IpLookupService.new
    result = lookup.perform(remote_address)
    return if result&.country.blank?

    seen = seen_countries(lookup, user_id, signed_in_at)
    return if seen.blank? || seen.include?(result.country)

    browser = Browser.new(user_agent.to_s)
    { city: result.city, country: result.country, ip: remote_address,
      browser_name: browser.name, platform_name: browser.platform.name }
  end

  def seen_countries(lookup, user_id, signed_in_at)
    Enterprise::AuditLog.where(user_id: user_id, action: 'sign_in')
                        .where(created_at: ...Time.zone.parse(signed_in_at.to_s))
                        .order(created_at: :desc)
                        .limit(PRIOR_SIGN_IN_LIMIT)
                        .pluck(:remote_address)
                        .compact.uniq
                        .filter_map { |ip| lookup.perform(ip)&.country }
                        .uniq
  end
end
