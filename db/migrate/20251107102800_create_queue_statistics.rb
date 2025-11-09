class CreateQueueStatistics < ActiveRecord::Migration[7.1]
  def change
    create_table :queue_statistics do |t|
      t.references :account, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :total_queued, default: 0, null: false
      t.integer :total_assigned, default: 0, null: false
      t.integer :total_left, default: 0, null: false
      t.integer :average_wait_time_seconds, default: 0, null: false
      t.integer :max_wait_time_seconds, default: 0, null: false

      t.timestamps
    end

    add_index :queue_statistics, [:account_id, :date], unique: true
  end
end
