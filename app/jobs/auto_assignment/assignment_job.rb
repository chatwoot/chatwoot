class AutoAssignment::AssignmentJob < ApplicationJob
  queue_as :default

  IN_FLIGHT_TTL = 5.minutes

  # Coalesce per inbox: at most one AssignmentJob per inbox is in-flight
  # (queued or running) at any time. The marker is cleared in `ensure` after
  # perform returns so the next trigger can enqueue another run.
  def self.enqueue_for_inbox(inbox_id)
    key = format(::Redis::Alfred::AUTO_ASSIGNMENT_IN_FLIGHT_KEY, inbox_id: inbox_id)
    return false unless ::Redis::Alfred.set(key, '1', nx: true, ex: IN_FLIGHT_TTL)

    perform_later(inbox_id: inbox_id)
    true
  end

  def perform(inbox_id:)
    inbox = Inbox.find_by(id: inbox_id)
    return unless inbox

    service = AutoAssignment::AssignmentService.new(inbox: inbox)
    assigned_count = service.perform_bulk_assignment(limit: bulk_assignment_limit)
    Rails.logger.info "Assigned #{assigned_count} conversations for inbox #{inbox.id}"
  rescue StandardError => e
    Rails.logger.error "Bulk assignment failed for inbox #{inbox_id}: #{e.message}"
    raise e if Rails.env.test?
  ensure
    ::Redis::Alfred.delete(format(::Redis::Alfred::AUTO_ASSIGNMENT_IN_FLIGHT_KEY, inbox_id: inbox_id))
  end

  private

  def bulk_assignment_limit
    ENV.fetch('AUTO_ASSIGNMENT_BULK_LIMIT', 100).to_i
  end
end
