class CreateRateLimitOverrides < ActiveRecord::Migration[7.0]
  def change
    create_table :weave_core_rate_limit_overrides do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :category, null: false
      t.integer :override_limit, null: false
      t.text :reason, null: false
      t.datetime :expires_at, null: false
      t.bigint :created_by_user_id, null: false
      t.boolean :notification_sent, default: false
      t.text :notes

      t.timestamps

      t.index [:account_id, :category, :expires_at], name: 'idx_rate_limit_overrides_active'
      t.index :expires_at
    end

    add_foreign_key :weave_core_rate_limit_overrides, :users, column: :created_by_user_id
  end
end