namespace :audit_log do
  # Run manually to backfill geo location on existing audit rows.
  task backfill_ip_location: :environment do
    Enterprise::AuditLogIpLocationBackfillJob.perform_later
  end
end
