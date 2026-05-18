class AddArchivedAtToKanbanCards < ActiveRecord::Migration[7.1]
  def change
    add_column :chatwoot_kanban_cards, :archived_at, :datetime
    add_index  :chatwoot_kanban_cards, :archived_at

    # Backfill not needed — all existing cards remain active.
  end
end
