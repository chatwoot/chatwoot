class AddFeaturesAndDescriptionToSubscriptionPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_plans, :features, :jsonb, default: [], null: false
    add_column :subscription_plans, :description, :text
  end
end
