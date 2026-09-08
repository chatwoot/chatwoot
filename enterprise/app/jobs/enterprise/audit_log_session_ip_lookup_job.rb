class Enterprise::AuditLogSessionIpLookupJob < ApplicationJob
  queue_as :low

  # Sign-in and sign-out write one audit row per account the user belongs to, all
  # sharing a request uuid and address, so a single lookup covers the whole batch.
  def perform(request_uuid, remote_address)
    return if request_uuid.blank? || remote_address.blank?

    audits = eligible_audits(request_uuid, remote_address)
    return if audits.empty?

    result = IpLookupService.new.perform(remote_address)
    return unless result

    audits.update_all(city: result.city, country: result.country, country_code: result.country_code) # rubocop:disable Rails/SkipsModelValidations
  rescue StandardError => e
    Rails.logger.warn "Enterprise::AuditLogSessionIpLookupJob failed: #{e.message}"
  end

  private

  def eligible_audits(request_uuid, remote_address)
    Enterprise::AuditLog.where(request_uuid: request_uuid, remote_address: remote_address)
                        .where(associated_type: 'Account', associated_id: Account.feature_ip_lookup.select(:id))
  end
end
