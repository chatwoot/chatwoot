class CreateAiAgentTemplate < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agent_templates do |t|
      t.text :system_prompt, null: false
      t.text :welcoming_message, null: false
      t.timestamps
    end

    add_column :ai_agents, :template_id, :bigint, null: true
  end
end
