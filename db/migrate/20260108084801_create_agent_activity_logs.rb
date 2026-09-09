class CreateAgentActivityLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :agent_activity_logs do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.string :status, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.integer :duration_seconds

      t.timestamps
    end

    add_index :agent_activity_logs, [:account_id, :user_id, :started_at]
    add_index :agent_activity_logs, [:account_id, :started_at, :ended_at]
  end
end
