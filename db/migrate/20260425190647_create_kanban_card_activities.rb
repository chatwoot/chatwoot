class CreateKanbanCardActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_card_activities do |t|
      t.references :kanban_card, null: false, foreign_key: true
      t.references :from_column, foreign_key: { to_table: :kanban_columns }
      t.references :to_column, null: false, foreign_key: { to_table: :kanban_columns }
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :kanban_card_activities, [:kanban_card_id, :created_at]
  end
end
