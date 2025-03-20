class CreateAiAgents < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agents do |t|
      t.integer :account_id, null: false
      t.string :name, null: false
      t.text :system_prompts, null: false
      t.text :welcoming_message, null: false
      t.text :routing_conditions
      t.boolean :control_flow_rules, default: false, null: false
      t.string :model_name, default: 'gpt-4o'
      t.integer :history_limit, default: 20
      t.integer :context_limit, default: 10
      t.integer :message_await, default: 5
      t.integer :message_limit, default: 1000
      t.string :timezone, default: 'UTC', null: false
      t.timestamps
    end
  end
end
