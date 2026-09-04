class Enterprise::AuditLogIpLocationBackfillJob < ApplicationJob
  queue_as :low

  BATCH_SIZE = 500
  BATCH_DELAY = 5.seconds

  # Walks the audits table one bounded batch per run, rescheduling itself for
  # the next cursor so the low queue is never flooded on a large backfill.
  def perform(cursor = 0)
    audits = Enterprise::AuditLog.where.not(remote_address: nil)
                                 .where('city IS NULL OR country IS NULL OR country_code IS NULL')
                                 .where('id > ?', cursor)
                                 .order(:id)
                                 .limit(BATCH_SIZE)
                                 .to_a
    return if audits.empty?

    audits.each(&:resolve_ip_location!)
    self.class.set(wait: BATCH_DELAY).perform_later(audits.last.id)
  end
end
