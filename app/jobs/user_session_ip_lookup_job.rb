class UserSessionIpLookupJob < ApplicationJob
  queue_as :low

  def perform(session)
    return if session.ip_address.blank?

    result = IpLookupService.new.perform(session.ip_address)
    return unless result

    session.update_columns( # rubocop:disable Rails/SkipsModelValidations
      city: result.city,
      country: result.country,
      country_code: result.country_code
    )
  rescue StandardError => e
    Rails.logger.warn "UserSessionIpLookupJob failed: #{e.message}"
  end
end
