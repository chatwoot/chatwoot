class AddAiAgentsToPricingPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :pricing_plans, :ai_agents, :integer, default: 0
  end
end
