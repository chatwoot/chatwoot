class AddNotifyUserIdsToSlaPolicies < ActiveRecord::Migration[7.1]
  def change
    add_column :sla_policies, :notify_user_ids, :bigint, array: true, default: []
  end
end
