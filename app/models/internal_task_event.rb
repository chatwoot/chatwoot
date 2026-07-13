class InternalTaskEvent < ApplicationRecord
  belongs_to :internal_task
  belongs_to :user, optional: true

  validates :event_type, presence: true

  after_create_commit :broadcast_task_activity, unless: :created_event?

  def self.record!(task:, user:, event_type:, metadata: {})
    create!(
      internal_task: task,
      user: user,
      event_type: event_type,
      metadata: metadata
    )
  end

  private

  def created_event?
    event_type == 'created'
  end

  def broadcast_task_activity
    # touch bumps updated_at and fires after_update_commit → dispatch_updated_event once
    internal_task.touch
  end
end
