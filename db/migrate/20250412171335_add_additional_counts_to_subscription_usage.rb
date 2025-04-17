class AddAdditionalCountsToSubscriptionUsage < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_usage, :additional_mau_count, :integer, default: 0, null: false
    add_column :subscription_usage, :additional_ai_response_count, :integer, default: 0, null: false
  end
end
