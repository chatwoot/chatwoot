class RemoveUserFromAgentBot < ActiveRecord::Migration[6.0]
  def change
  	remove_column :agent_bots, :user_id
  	remove_column :agent_bots, :account_id
  end
end
