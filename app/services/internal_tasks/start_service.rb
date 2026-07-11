class InternalTasks::StartService
  pattr_initialize [:task!, :user!]

  def perform
    task.update!(status: 'in_progress', started_at: task.started_at || Time.current, assigned_to: task.assigned_to || user)
    task
  end
end
