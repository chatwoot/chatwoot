class RenameCaptainTablesToAiAgent < ActiveRecord::Migration[7.0]
  def change
    # Rename tables
    rename_table :captain_assistants, :ai_agent_topics
    rename_table :captain_assistant_responses, :ai_agent_topic_responses
    rename_table :captain_documents, :ai_agent_documents
    rename_table :captain_inboxes, :ai_agent_inboxes

    # Update foreign keys and column names in ai_agent_topics (previously captain_assistants)
    # No column renames needed for this table

    # Update foreign keys and column names in ai_agent_topic_responses (previously captain_assistant_responses)
    rename_column :ai_agent_topic_responses, :assistant_id, :topic_id

    # Update foreign keys and column names in ai_agent_documents (previously captain_documents)
    rename_column :ai_agent_documents, :assistant_id, :topic_id

    # Update foreign keys and column names in ai_agent_inboxes (previously captain_inboxes)
    rename_column :ai_agent_inboxes, :captain_assistant_id, :ai_agent_topic_id

    # Rename indexes
    rename_index :ai_agent_topics, 'index_captain_assistants_on_account_id', 'index_ai_agent_topics_on_account_id'

    rename_index :ai_agent_topic_responses, 'index_captain_assistant_responses_on_account_id', 'index_ai_agent_topic_responses_on_account_id'
    rename_index :ai_agent_topic_responses, 'index_captain_assistant_responses_on_assistant_id', 'index_ai_agent_topic_responses_on_topic_id'
    rename_index :ai_agent_topic_responses, 'index_captain_assistant_responses_on_status', 'index_ai_agent_topic_responses_on_status'
    rename_index :ai_agent_topic_responses, 'idx_cap_asst_resp_on_documentable', 'idx_ai_agent_topic_resp_on_documentable'

    rename_index :ai_agent_documents, 'index_captain_documents_on_account_id', 'index_ai_agent_documents_on_account_id'
    rename_index :ai_agent_documents, 'index_captain_documents_on_assistant_id', 'index_ai_agent_documents_on_topic_id'
    rename_index :ai_agent_documents, 'index_captain_documents_on_assistant_id_and_external_link', 'index_ai_agent_documents_on_topic_id_and_external_link'
    rename_index :ai_agent_documents, 'index_captain_documents_on_status', 'index_ai_agent_documents_on_status'

    rename_index :ai_agent_inboxes, 'index_captain_inboxes_on_captain_assistant_id', 'index_ai_agent_inboxes_on_ai_agent_topic_id'
    rename_index :ai_agent_inboxes, 'index_captain_inboxes_on_captain_assistant_id_and_inbox_id', 'index_ai_agent_inboxes_on_ai_agent_topic_id_and_inbox_id'
    rename_index :ai_agent_inboxes, 'index_captain_inboxes_on_inbox_id', 'index_ai_agent_inboxes_on_inbox_id'
  end
end 