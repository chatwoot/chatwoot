class AutoAssignment::AssignmentJob < MutexApplicationJob
  queue_as :default

  COALESCE_TTL = 60.seconds.to_i
  RUNNING_LOCK_TTL = 5.minutes

  # Event-driven, so a contended job must re-queue rather than drop. Coalesce
  # caps the queue depth, so retry storms stay bounded.
  retry_on LockAcquisitionError, wait: 10.seconds, attempts: 30

  # Coalesce bursts of triggers per inbox: while a job is queued or running
  # for this inbox, further enqueues are no-ops.
  def self.enqueue_for_inbox(inbox_id)
    key = format(::Redis::Alfred::AUTO_ASSIGNMENT_QUEUED_KEY, inbox_id: inbox_id)
    return false unless ::Redis::Alfred.set(key, '1', nx: true, ex: COALESCE_TTL)

    perform_later(inbox_id: inbox_id)
    true
  end

  def perform(inbox_id:)
    inbox = Inbox.find_by(id: inbox_id)
    return unless inbox

    with_lock(format(::Redis::Alfred::AUTO_ASSIGNMENT_RUNNING_MUTEX, inbox_id: inbox_id), RUNNING_LOCK_TTL) do
      # Clear inside the lock so contended jobs that fail to acquire it cannot
      # reopen the coalesce gate while work is still in-flight.
      ::Redis::Alfred.delete(format(::Redis::Alfred::AUTO_ASSIGNMENT_QUEUED_KEY, inbox_id: inbox_id))

      service = AutoAssignment::AssignmentService.new(inbox: inbox)
      assigned_count = service.perform_bulk_assignment(limit: bulk_assignment_limit)
      Rails.logger.info "Assigned #{assigned_count} conversations for inbox #{inbox.id}"
    end
  rescue LockAcquisitionError
    raise
  rescue StandardError => e
    Rails.logger.error "Bulk assignment failed for inbox #{inbox_id}: #{e.message}"
    raise e if Rails.env.test?
  end

  private

  def bulk_assignment_limit
    ENV.fetch('AUTO_ASSIGNMENT_BULK_LIMIT', 100).to_i
  end
end
