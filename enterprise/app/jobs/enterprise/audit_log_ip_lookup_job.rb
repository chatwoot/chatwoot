class Enterprise::AuditLogIpLookupJob < ApplicationJob
  queue_as :low
  discard_on ActiveJob::DeserializationError

  def perform(audit)
    return if audit.remote_address.blank?

    result = IpLookupService.new.perform(audit.remote_address)
    return unless result

    audit.update_columns( # rubocop:disable Rails/SkipsModelValidations
      city: result.city,
      country: result.country,
      country_code: result.country_code
    )
  rescue StandardError => e
    Rails.logger.warn "Enterprise::AuditLogIpLookupJob failed: #{e.message}"
  end
end
