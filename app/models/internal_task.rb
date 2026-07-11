class InternalTask < ApplicationRecord
  STATUSES = %w[pending in_progress blocked waiting_external completed cancelled].freeze
  PRIORITIES = %w[normal high urgent].freeze
  OPEN_STATUSES = %w[pending in_progress blocked waiting_external].freeze

  belongs_to :account
  belongs_to :conversation
  belongs_to :task_template, optional: true
  belongs_to :created_by, class_name: 'User'
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :team, optional: true
  belongs_to :source_message, class_name: 'Message', optional: true
  belongs_to :depends_on_task, class_name: 'InternalTask', optional: true
  has_many :dependent_tasks, class_name: 'InternalTask', foreign_key: :depends_on_task_id, dependent: :nullify
  has_many :events, class_name: 'InternalTaskEvent', dependent: :destroy_async

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }
  validate :source_message_belongs_to_conversation

  before_validation :ensure_account_id
  after_create_commit :record_created_event, :dispatch_created_event
  after_update_commit :record_update_events, :dispatch_updated_event

  scope :open, -> { where(status: OPEN_STATUSES) }
  scope :for_user, ->(user) { where(assigned_to_id: user.id) }
  scope :for_team, ->(team_id) { where(team_id: team_id) }
  scope :unclaimed, -> { where(assigned_to_id: nil) }
  scope :overdue, -> { where('due_at < ?', Time.current).where(status: OPEN_STATUSES) }

  def open?
    OPEN_STATUSES.include?(status)
  end

  def push_event_data(include_events: false)
    data = {
      id: id,
      title: title,
      description: description,
      status: status,
      priority: priority,
      metadata: metadata,
      due_at: due_at&.to_i,
      claimed_at: claimed_at&.to_i,
      started_at: started_at&.to_i,
      completed_at: completed_at&.to_i,
      conversation_id: conversation_id,
      task_template_id: task_template_id,
      assigned_to_id: assigned_to_id,
      team_id: team_id,
      depends_on_task_id: depends_on_task_id,
      source_message_id: source_message_id,
      account_id: account_id,
      created_at: created_at.to_i,
      updated_at: updated_at.to_i
    }

    if conversation.present?
      data[:conversation] = {
        id: conversation.display_id,
        contact_name: conversation.contact&.name
      }
    end

    data[:created_by] = created_by.push_event_data if created_by.present?
    data[:assigned_to] = assigned_to.push_event_data if assigned_to.present?
    data[:team] = { id: team.id, name: team.name } if team.present?

    if task_template.present?
      data[:task_template] = {
        id: task_template.id,
        key: task_template.key,
        title: task_template.title,
        metadata_schema: task_template.metadata_schema
      }
    end

    if include_events
      data[:events] = events.sort_by(&:created_at).map do |event|
        {
          id: event.id,
          event_type: event.event_type,
          metadata: event.metadata,
          created_at: event.created_at.to_i,
          user: event.user&.push_event_data
        }.compact
      end
    end

    data
  end

  def dispatch_created_event
    Rails.configuration.dispatcher.dispatch(Events::Types::INTERNAL_TASK_CREATED, Time.zone.now, internal_task: self)
  end

  def dispatch_updated_event
    Rails.configuration.dispatcher.dispatch(Events::Types::INTERNAL_TASK_UPDATED, Time.zone.now, internal_task: self)
  end

  private

  def ensure_account_id
    self.account_id = conversation&.account_id
  end

  def source_message_belongs_to_conversation
    return if source_message_id.blank?

    errors.add(:source_message_id, 'must belong to the same conversation') if source_message&.conversation_id != conversation_id
  end

  def record_created_event
    InternalTaskEvent.record!(task: self, user: created_by, event_type: 'created', metadata: creation_metadata)
  end

  def record_update_events
    user = Current.user
    return if user.blank?

    if saved_change_to_status?
      event_type = status == 'completed' ? 'completed' : (status == 'cancelled' ? 'cancelled' : 'status_changed')
      InternalTaskEvent.record!(task: self, user: user, event_type: event_type,
                              metadata: { from: status_before_last_save, to: status })
    end

    if saved_change_to_claimed_at? && claimed_at.present?
      InternalTaskEvent.record!(task: self, user: user, event_type: 'claimed', metadata: {})
    end

    if saved_change_to_assigned_to_id?
      InternalTaskEvent.record!(task: self, user: user, event_type: 'assigned',
                              metadata: { from: assigned_to_id_before_last_save, to: assigned_to_id })
    end

    if saved_change_to_team_id?
      InternalTaskEvent.record!(task: self, user: user, event_type: 'team_changed',
                              metadata: { from: team_id_before_last_save, to: team_id })
    end

    if saved_change_to_metadata?
      InternalTaskEvent.record!(task: self, user: user, event_type: 'metadata_updated', metadata: metadata)
    end
  end

  def creation_metadata
    {
      title: title,
      team_id: team_id,
      assigned_to_id: assigned_to_id,
      task_template_id: task_template_id,
      source_message_id: source_message_id
    }
  end
end
