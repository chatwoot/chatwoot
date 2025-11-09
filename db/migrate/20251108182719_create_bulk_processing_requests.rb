class CreateBulkProcessingRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :bulk_processing_requests do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: 'PENDING'
      t.integer :total_records, default: 0
      t.integer :processed_records, default: 0
      t.integer :failed_records, default: 0
      t.decimal :progress, precision: 5, scale: 2, default: 0.0
      t.text :error_message
      t.string :file_name
      t.string :entity_type, null: false

      t.timestamps
    end

    add_index :bulk_processing_requests, :status
    add_index :bulk_processing_requests, :created_at
  end
end
