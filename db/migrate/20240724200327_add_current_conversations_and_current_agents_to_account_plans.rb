class AddCurrentConversationsAndCurrentAgentsToAccountPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :account_plans, :current_conversations, :integer, null: false, default: 0
    add_column :account_plans, :current_agents, :integer, null: false, default: 0
  end
end
