class InternalTasks::ClaimService
  pattr_initialize [:task!, :user!]

  def perform
    task.with_lock do
      task.reload
      if task.assigned_to_id.present? && task.assigned_to_id != user.id
        raise InternalTasks::AlreadyClaimedError, task
      end

      task.update!(assigned_to: user, claimed_at: Time.current)
    end
    task
  end
end
