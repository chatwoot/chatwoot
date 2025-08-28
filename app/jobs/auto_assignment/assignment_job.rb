class AutoAssignment::AssignmentJob < ApplicationJob
  queue_as :default

  def perform(inbox_id:)
    inbox = Inbox.find_by(id: inbox_id)
    return unless inbox

    service = AutoAssignment::AssignmentService.new(inbox: inbox)

    assigned_count = service.perform_bulk_assignment(limit: bulk_assignment_limit)
    success_message = I18n.t('jobs.auto_assignment.assignment_job.bulk_assignment_success',
                             assigned_count: assigned_count,
                             inbox_id: inbox.id)
    Rails.logger.info success_message
  rescue StandardError => e
    error_message = I18n.t('jobs.auto_assignment.assignment_job.bulk_assignment_failed',
                           inbox_id: inbox.id,
                           error_message: e.message)
    Rails.logger.error error_message
    raise e if Rails.env.test?
  end

  private

  def bulk_assignment_limit
    ENV.fetch('AUTO_ASSIGNMENT_BULK_LIMIT', 100).to_i
  end
end
