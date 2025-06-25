class AddDefaultValueToJsonbColums < ActiveRecord::Migration[6.0]
  def change
    change_column_default :contacts, :additional_attributes, from: nil, to: {}
    change_column_default :conversations, :additional_attributes, from: nil, to: {}
    change_column_default :installation_configs, :serialized_value, from: '{}', to: {}
    change_column_default :notification_subscriptions, :subscription_attributes, from: '{}', to: {}
  end
end
