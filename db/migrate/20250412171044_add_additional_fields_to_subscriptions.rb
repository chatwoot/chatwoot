class AddAdditionalFieldsToSubscriptions < ActiveRecord::Migration[7.0]
  def change
    add_column :subscriptions, :additional_mau, :integer, default: 0, null: false
    add_column :subscriptions, :additional_ai_responses, :integer, default: 0, null: false
  end
end
