class CreateChatwootKanbanBoards < ActiveRecord::Migration[7.1]
  def change
    create_table :chatwoot_kanban_boards do |t|
      t.references :account, null: false, foreign_key: { to_table: :accounts, on_delete: :cascade }, index: true
      t.string  :name,        null: false, limit: 120
      t.text    :description
      t.jsonb   :settings,    null: false, default: {}
      t.bigint  :created_by_id
      t.datetime :archived_at
      t.timestamps
    end

    add_index :chatwoot_kanban_boards, :created_by_id
    add_index :chatwoot_kanban_boards, [:account_id, :archived_at]
  end
end
