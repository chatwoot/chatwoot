class CreateAiAgentSelectedLabels < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agent_selected_labels do |t|
      t.references :ai_agent, null: true, foreign_key: true
      t.references :label, null: true, foreign_key: true
      t.text :label_condition, null: true

      t.timestamps
    end
  end
end
