class AddCitedDocumentIdsToAgentSessions < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_sessions, :cited_document_ids, :jsonb, default: [], null: false
  end
end
