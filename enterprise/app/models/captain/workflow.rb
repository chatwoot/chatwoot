class Captain::Workflow < ApplicationRecord
  self.table_name = 'captain_workflows'

  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :account
  has_many :executions, class_name: 'Captain::WorkflowExecution', dependent: :destroy_async

  validates :name, presence: true
  validates :trigger_event, presence: true
  validates :assistant_id, presence: true
  validates :account_id, presence: true
  validates :trigger_event, inclusion: { in: %w[conversation_created message_created conversation_resolved] }

  scope :enabled, -> { where(enabled: true) }
  scope :for_event, ->(event) { where(trigger_event: event) }
end
