class AddUsedFaqIdsToAgentSessions < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_sessions, :used_faq_ids, :jsonb, default: [], null: false
  end
end
