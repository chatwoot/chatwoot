class Enterprise::AuditLogIpLookupJob < ApplicationJob
  queue_as :within_10_minutes
  discard_on ActiveJob::DeserializationError

  def perform(audit)
    audit.resolve_ip_location!
  rescue StandardError => e
    Rails.logger.warn "Enterprise::AuditLogIpLookupJob failed: #{e.message}"
  end
end
