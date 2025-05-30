class RenameCaptainToAiAgent < ActiveRecord::Migration[7.0]
  def change
    # Create the AI Agent tables directly
    create_table :ai_agent_topics do |t|
      t.string :name, null: false
      t.string :description
      t.jsonb :config, null: false, default: {}
      t.references :account, null: false
      t.timestamps
    end
    add_index :ai_agent_topics, :account_id

    create_table :ai_agent_documents do |t|
      t.string :name
      t.string :external_link, null: false
      t.text :content
      t.references :topic, null: false
      t.references :account, null: false
      t.integer :status, default: 0, null: false
      t.timestamps
    end
    add_index :ai_agent_documents, :account_id
    add_index :ai_agent_documents, :topic_id
    add_index :ai_agent_documents, [:topic_id, :external_link], unique: true

    create_table :ai_agent_topic_responses do |t|
      t.string :question, null: false
      t.text :answer, null: false
      t.references :topic, null: false
      t.references :account, null: false
      t.bigint :documentable_id
      t.string :documentable_type
      t.integer :status, default: 1, null: false
      t.vector :embedding, dimensions: 1536
      t.timestamps
    end
    add_index :ai_agent_topic_responses, :account_id
    add_index :ai_agent_topic_responses, :topic_id
    add_index :ai_agent_topic_responses, [:documentable_id, :documentable_type]
    add_index :ai_agent_topic_responses, :status
    add_index :ai_agent_topic_responses, :embedding, using: :ivfflat, name: 'vector_idx_knowledge_entries_embedding', opclass: :vector_l2_ops

    create_table :ai_agent_inboxes do |t|
      t.references :ai_agent_topic, null: false
      t.references :inbox, null: false
      t.timestamps
    end
    add_index :ai_agent_inboxes, [:ai_agent_topic_id, :inbox_id], unique: true
  end
end 