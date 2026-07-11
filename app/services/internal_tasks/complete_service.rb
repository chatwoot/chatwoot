class InternalTasks::CompleteService
  pattr_initialize [:task!, :user!]

  def perform(metadata: {}, comment: nil)
    merged_metadata = task.metadata.merge(metadata.stringify_keys)
    task.update!(status: 'completed', completed_at: Time.current, metadata: merged_metadata)
    InternalTaskEvent.record!(task: task, user: user, event_type: 'comment', metadata: { comment: comment }) if comment.present?
    task
  end
end
