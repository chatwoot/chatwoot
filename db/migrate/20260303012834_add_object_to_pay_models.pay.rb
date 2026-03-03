# This migration comes from pay (originally 20250415151129)
class AddObjectToPayModels < ActiveRecord::Migration[6.0]
  def change
    add_column :pay_charges, :object, Pay::Adapter.json_column_type
    add_column :pay_customers, :object, Pay::Adapter.json_column_type
    add_column :pay_subscriptions, :object, Pay::Adapter.json_column_type
  end
end
