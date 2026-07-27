class CreateFailedEmailRetryBatches < ActiveRecord::Migration[7.1]
  def change
    create_table :failed_email_retry_batches do |t|
      t.references :requested_by, null: false, type: :integer, foreign_key: { to_table: :users }
      t.integer :lookback_hours, null: false
      t.datetime :range_start, null: false
      t.datetime :range_end, null: false
      t.integer :status, null: false, default: 0
      t.integer :candidate_count, null: false, default: 0
      t.integer :eligible_count, null: false, default: 0
      t.integer :scheduled_count, null: false, default: 0
      t.integer :skipped_count, null: false, default: 0
      t.integer :error_count, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at
      t.text :error_message

      t.timestamps
    end

    add_index :failed_email_retry_batches, [:status, :created_at]
  end
end
