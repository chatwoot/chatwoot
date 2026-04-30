# frozen_string_literal: true

class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.jsonb :execution_config, default: {}
      t.string :entity_type
      t.bigint :entity_id
      t.integer :status, default: 0, null: false
      t.integer :action_type, default: 0, null: false
      t.datetime :scheduled_at
      t.bigint :assignee_id
      t.bigint :agent_bot_id
      t.references :account, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tasks, [:entity_type, :entity_id]
    add_index :tasks, [:account_id, :status]
    add_index :tasks, [:account_id, :created_at]
    add_index :tasks, [:account_id, :scheduled_at, :status]
    add_index :tasks, :assignee_id
    add_index :tasks, :agent_bot_id

    add_foreign_key :tasks, :users, column: :assignee_id
    add_foreign_key :tasks, :agent_bots, column: :agent_bot_id
  end
end
