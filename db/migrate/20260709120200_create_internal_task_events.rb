class CreateInternalTaskEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :internal_task_events do |t|
      t.references :internal_task, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :internal_task_events, [:internal_task_id, :created_at]
  end
end
