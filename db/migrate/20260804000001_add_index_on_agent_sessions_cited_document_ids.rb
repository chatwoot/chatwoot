class AddIndexOnAgentSessionsCitedDocumentIds < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :agent_sessions, :cited_document_ids, using: :gin, algorithm: :concurrently
  end
end
