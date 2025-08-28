class AutoAssignment::PeriodicAssignmentJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.find_each do |account|
      next unless account.feature_enabled?('assignment_v2')

      account.inboxes.joins(:assignment_policy).find_each do |inbox|
        next unless inbox.auto_assignment_enabled?

        AutoAssignment::AssignmentJob.perform_later(inbox_id: inbox.id)
      end
    end
  end
end
