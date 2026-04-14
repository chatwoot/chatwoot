class AutoAssignment::AssignmentJob < ApplicationJob
  queue_as :default

  def perform(inbox_id:)
    inbox = Inbox.find_by(id: inbox_id)
    return unless inbox

    service = AutoAssignment::AssignmentService.new(inbox: inbox)

    assigned_count = service.perform_bulk_assignment(limit: bulk_assignment_limit)
    Rails.logger.info "Assigned #{assigned_count} conversations for inbox #{inbox.id}"
  rescue StandardError => e
    Rails.logger.error "Bulk assignment failed for inbox #{inbox_id}: #{e.message}"
    raise e if Rails.env.test?
  end

  private

  def bulk_assignment_limit
    ENV.fetch('AUTO_ASSIGNMENT_BULK_LIMIT', 100).to_i
  end
end
