class AddEnteredStageAtToKanbanCards < ActiveRecord::Migration[7.1]
  def up
    add_column :kanban_cards, :entered_stage_at, :datetime
    KanbanCard.in_batches(of: 1000).update_all('entered_stage_at = created_at') # rubocop:disable Rails/SkipsModelValidations
    change_column_null :kanban_cards, :entered_stage_at, false
    add_index :kanban_cards, [:kanban_column_id, :entered_stage_at],
              name: 'index_kanban_cards_on_column_and_entered_stage_at'
  end

  def down
    remove_index :kanban_cards, name: 'index_kanban_cards_on_column_and_entered_stage_at'
    remove_column :kanban_cards, :entered_stage_at
  end
end
