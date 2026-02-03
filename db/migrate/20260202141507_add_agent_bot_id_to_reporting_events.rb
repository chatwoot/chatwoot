class AddAgentBotIdToReportingEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :reporting_events, :agent_bot_id, :bigint
    add_index :reporting_events, :agent_bot_id
  end
end
