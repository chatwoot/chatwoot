class CreateSubscriptionUsage < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_usage do |t|
      t.references :subscription, null: false, foreign_key: true
      t.integer :mau_count, default: 0
      t.integer :ai_responses_count, default: 0
      t.datetime :last_reset_at
      t.timestamps
    end
  end
end
