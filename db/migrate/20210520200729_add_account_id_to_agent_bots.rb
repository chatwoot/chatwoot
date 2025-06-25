class AddAccountIdToAgentBots < ActiveRecord::Migration[6.0]
  def change
    remove_column :agent_bots, :hide_input_for_bot_conversations, :boolean
    add_reference :agent_bots, :account, foreign_key: true
  end
end
