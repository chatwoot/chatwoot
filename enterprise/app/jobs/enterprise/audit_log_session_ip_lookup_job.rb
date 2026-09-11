class Enterprise::AuditLogSessionIpLookupJob < ApplicationJob
  queue_as :low

  # Every row of a sign-in carries the same address, so one lookup covers the batch.
  def perform(audit_ids, remote_address)
    return if audit_ids.blank? || remote_address.blank?

    audits = eligible_audits(audit_ids)
    return if audits.empty?

    result = IpLookupService.new.perform(remote_address)
    return unless result

    audits.update_all(city: result.city, country: result.country, country_code: result.country_code) # rubocop:disable Rails/SkipsModelValidations
  rescue StandardError => e
    Rails.logger.warn "Enterprise::AuditLogSessionIpLookupJob failed: #{e.message}"
  end

  private

  def eligible_audits(audit_ids)
    Enterprise::AuditLog.where(id: audit_ids)
                        .where(associated_type: 'Account', associated_id: Account.feature_ip_lookup.select(:id))
  end
end
