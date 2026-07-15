class CreateKanbanBoards < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_boards do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :board_type, null: false, default: 0

      t.timestamps
    end

    add_index :kanban_boards, [:account_id, :name], unique: true
  end
end
