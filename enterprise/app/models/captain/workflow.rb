class Captain::Workflow < ApplicationRecord
  self.table_name = 'captain_workflows'

  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :account
  has_many :executions, class_name: 'Captain::WorkflowExecution', dependent: :destroy_async

  validates :name, presence: true
  validates :assistant_id, presence: true
  validates :account_id, presence: true

  scope :enabled, -> { where(enabled: true) }
end
