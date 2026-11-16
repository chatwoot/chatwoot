class AddIndexToConversationsSlaPolicyId < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :conversations, :sla_policy_id, where: 'sla_policy_id IS NOT NULL', algorithm: :concurrently
  end
end
