class CreateConversationMonitorDailyUsages < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_monitor_daily_usages do |t|
      t.references :account, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.date :usage_date, null: false
      t.integer :calls_count, null: false, default: 0
      t.datetime :limit_reached_at
      t.timestamps
    end

    add_index :conversation_monitor_daily_usages, [:account_id, :usage_date], unique: true, name: 'index_monitor_daily_usage_unique'
    add_check_constraint :conversation_monitor_daily_usages, 'calls_count >= 0', name: 'monitor_daily_usage_nonnegative'
  end
end
