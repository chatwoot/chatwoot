# This migration comes from pay (originally 1)
class CreatePayTables < ActiveRecord::Migration[6.0]
  def change
    primary_key_type, foreign_key_type = primary_and_foreign_key_types

    create_table :pay_customers, id: primary_key_type do |t|
      t.belongs_to :owner, polymorphic: true, index: false, type: foreign_key_type
      t.string :processor, null: false
      t.string :processor_id
      t.boolean :default
      t.public_send Pay::Adapter.json_column_type, :data
      t.string :stripe_account
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :pay_customers, [:owner_type, :owner_id, :deleted_at], name: :pay_customer_owner_index, unique: true
    add_index :pay_customers, [:processor, :processor_id], unique: true

    create_table :pay_merchants, id: primary_key_type do |t|
      t.belongs_to :owner, polymorphic: true, index: false, type: foreign_key_type
      t.string :processor, null: false
      t.string :processor_id
      t.boolean :default
      t.public_send Pay::Adapter.json_column_type, :data
      t.timestamps
    end
    add_index :pay_merchants, [:owner_type, :owner_id, :processor]

    create_table :pay_payment_methods, id: primary_key_type do |t|
      t.belongs_to :customer, foreign_key: { to_table: :pay_customers }, null: false, index: false, type: foreign_key_type
      t.string :processor_id, null: false
      t.boolean :default
      t.string :type
      t.public_send Pay::Adapter.json_column_type, :data
      t.string :stripe_account
      t.timestamps
    end
    add_index :pay_payment_methods, [:customer_id, :processor_id], unique: true

    create_table :pay_subscriptions, id: primary_key_type do |t|
      t.belongs_to :customer, foreign_key: { to_table: :pay_customers }, null: false, index: false, type: foreign_key_type
      t.string :name, null: false
      t.string :processor_id, null: false
      t.string :processor_plan, null: false
      t.integer :quantity, default: 1, null: false
      t.string :status, null: false
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :trial_ends_at
      t.datetime :ends_at
      t.boolean :metered
      t.string :pause_behavior
      t.datetime :pause_starts_at
      t.datetime :pause_resumes_at
      t.decimal :application_fee_percent, precision: 8, scale: 2
      t.public_send Pay::Adapter.json_column_type, :metadata
      t.public_send Pay::Adapter.json_column_type, :data
      t.string :stripe_account
      t.string :payment_method_id
      t.timestamps
    end
    add_index :pay_subscriptions, [:customer_id, :processor_id], unique: true
    add_index :pay_subscriptions, [:metered]
    add_index :pay_subscriptions, [:pause_starts_at]

    create_table :pay_charges, id: primary_key_type do |t|
      t.belongs_to :customer, foreign_key: { to_table: :pay_customers }, null: false, index: false, type: foreign_key_type
      t.belongs_to :subscription, foreign_key: { to_table: :pay_subscriptions }, null: true, type: foreign_key_type
      t.string :processor_id, null: false
      t.integer :amount, null: false
      t.string :currency
      t.integer :application_fee_amount
      t.integer :amount_refunded
      t.public_send Pay::Adapter.json_column_type, :metadata
      t.public_send Pay::Adapter.json_column_type, :data
      t.string :stripe_account
      t.timestamps
    end
    add_index :pay_charges, [:customer_id, :processor_id], unique: true

    create_table :pay_webhooks, id: primary_key_type do |t|
      t.string :processor
      t.string :event_type
      t.public_send Pay::Adapter.json_column_type, :event
      t.timestamps
    end
  end

  private

  def primary_and_foreign_key_types
    config = Rails.configuration.generators
    setting = config.options[config.orm][:primary_key_type]
    primary_key_type = setting || :primary_key
    foreign_key_type = setting || :bigint
    [primary_key_type, foreign_key_type]
  end
end
