class CreateSaasSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :saas_subscriptions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :saas_plan, null: false, foreign_key: { to_table: :saas_plans }
      t.string :stripe_subscription_id
      t.string :stripe_customer_id
      t.integer :status, default: 0, null: false
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :trial_end
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :saas_subscriptions, :stripe_subscription_id, unique: true
    add_index :saas_subscriptions, :stripe_customer_id
    add_index :saas_subscriptions, :status
    add_index :saas_subscriptions, [:account_id, :status]
  end
end
