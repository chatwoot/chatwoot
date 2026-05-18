class AddAssigneeDueIndexToKanbanCards < ActiveRecord::Migration[7.1]
  # Composite index to speed up "my open cards" queries.
  def change
    add_index :chatwoot_kanban_cards, [:assignee_id, :due_at], where: 'archived_at IS NULL'
  end
end
