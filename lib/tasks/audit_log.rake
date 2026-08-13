namespace :audit_log do
  # Run manually to backfill geo location on existing audit rows.
  task backfill_ip_location: :environment do
    Enterprise::AuditLog.where.not(remote_address: nil).where(city: nil).find_each do |audit|
      Enterprise::AuditLogIpLookupJob.perform_later(audit)
    end
  end
end
