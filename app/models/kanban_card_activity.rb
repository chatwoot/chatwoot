class KanbanCardActivity < ApplicationRecord
  belongs_to :kanban_card
  belongs_to :from_column, class_name: 'KanbanColumn', optional: true
  belongs_to :to_column, class_name: 'KanbanColumn'
  belongs_to :user

  default_scope { order(created_at: :desc) }
end
