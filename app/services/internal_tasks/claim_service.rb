class InternalTasks::ClaimService
  pattr_initialize [:task!, :user!]

  def perform
    if task.assigned_to_id.present? && task.assigned_to_id != user.id
      raise StandardError, 'Task already claimed by another user'
    end

    task.update!(assigned_to: user, claimed_at: Time.current)
    task
  end
end
