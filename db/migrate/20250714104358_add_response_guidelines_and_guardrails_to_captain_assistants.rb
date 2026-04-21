class AddResponseGuidelinesAndGuardrailsToCaptainAssistants < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_assistants, :response_guidelines, :jsonb, default: []
    add_column :captain_assistants, :guardrails, :jsonb, default: []
  end
end
