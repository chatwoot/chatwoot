class Captain::WorkflowExecution < ApplicationRecord
  self.table_name = 'captain_workflow_executions'

  belongs_to :workflow, class_name: 'Captain::Workflow'
  belongs_to :account
  belongs_to :conversation, optional: true
  belongs_to :contact, optional: true

  enum :status, { pending: 0, running: 1, completed: 2, failed: 3, waiting_for_input: 4 }
end
