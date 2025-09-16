class CreateAccountBillingPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :account_billing_plans do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :plan_name, null: false, default: 'free'
      t.string :previous_plan
      t.datetime :upgraded_at
      t.datetime :trial_ends_at
      t.boolean :active, default: true, null: false

      # Stripe/Payment info
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.string :payment_status

      # Usage tracking
      t.integer :current_agents_count, default: 0
      t.integer :current_inboxes_count, default: 0
      t.integer :current_conversations_count, default: 0

      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :account_billing_plans, :plan_name
    add_index :account_billing_plans, :active
    add_index :account_billing_plans, :stripe_customer_id
  end
end
