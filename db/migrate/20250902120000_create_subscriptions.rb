class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :account, null: false, foreign_key: { to_table: :accounts }
      t.string :external_id, null: false # Stripe/PayPal subscription ID
      t.string :provider, null: false # 'stripe' or 'paypal'
      t.string :plan_key, null: false # basic, pro, premium, app, custom
      t.string :status, null: false # active, canceled, past_due, trial
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :trial_start
      t.datetime :trial_end
      t.integer :quantity, default: 1
      t.decimal :amount, precision: 10, scale: 2
      t.string :currency, default: 'USD'
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :subscriptions, :external_id, unique: true
    add_index :subscriptions, [:account_id, :provider]
    add_index :subscriptions, :status
    add_index :subscriptions, :plan_key
  end
end