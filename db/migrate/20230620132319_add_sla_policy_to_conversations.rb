class AddSlaPolicyToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :sla_policy_id, :bigint
  end
end
