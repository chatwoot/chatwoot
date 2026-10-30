class CreateDataExports < ActiveRecord::Migration[7.1]
  def change
    create_table :data_exports do |t|
      t.references :account, null: false, foreign_key: true
      t.references :initiated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :name, null: false
      t.string :data_type, null: false, default: 'contacts'
      t.integer :status, null: false, default: 0
      t.jsonb :export_options, null: false, default: {}
      t.string :active_run_id
      t.integer :processed_records, null: false, default: 0
      t.integer :total_records
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :notification_sent_at
      t.datetime :artifacts_expired_at
      t.timestamps
    end
    add_index :data_exports, [:account_id, :created_at]
    add_index :data_exports, [:status, :updated_at]
  end
end
