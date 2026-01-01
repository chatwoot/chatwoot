class DropCaptainTables < ActiveRecord::Migration[7.1]
  def up
    drop_table :captain_custom_tools, if_exists: true
    drop_table :captain_scenarios, if_exists: true
    drop_table :captain_inboxes, if_exists: true
    drop_table :captain_documents, if_exists: true
    drop_table :captain_assistant_responses, if_exists: true
    drop_table :captain_assistants, if_exists: true
    drop_table :copilot_messages, if_exists: true
    drop_table :copilot_threads, if_exists: true
    drop_table :article_embeddings, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
