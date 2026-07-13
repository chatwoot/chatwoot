class CreateInternalTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :internal_tasks do |t|
      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :task_template, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.jsonb :metadata, null: false, default: {}
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.references :team, foreign_key: true
      t.string :status, null: false, default: 'pending'
      t.string :priority, null: false, default: 'normal'
      t.datetime :due_at
      t.datetime :claimed_at
      t.datetime :started_at
      t.datetime :completed_at
      t.references :depends_on_task, foreign_key: { to_table: :internal_tasks }
      t.timestamps
    end

    add_index :internal_tasks, [:account_id, :assigned_to_id, :status]
    add_index :internal_tasks, [:account_id, :team_id, :status]
    add_index :internal_tasks, [:conversation_id, :status]
  end
end
