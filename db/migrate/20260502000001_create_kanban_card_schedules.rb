class CreateKanbanCardSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_card_schedules do |t|
      t.references :kanban_card, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.datetime :scheduled_at, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :kanban_card_schedules, [:kanban_card_id, :status]
    add_index :kanban_card_schedules, :scheduled_at
  end
end
