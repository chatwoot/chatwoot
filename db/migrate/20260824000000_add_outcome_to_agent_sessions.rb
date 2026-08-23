class AddOutcomeToAgentSessions < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_sessions, :outcome, :string
  end
end