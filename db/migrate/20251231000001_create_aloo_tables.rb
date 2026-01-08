# frozen_string_literal: true

class CreateAlooTables < ActiveRecord::Migration[7.0]
  def change
    create_aloo_assistants
    create_aloo_assistant_inboxes
    create_aloo_documents
    create_aloo_embeddings
    create_aloo_traces
    create_aloo_conversation_contexts
    create_aloo_memories
    create_aloo_message_feedbacks
  end

  private

  def create_aloo_assistants
    create_table :aloo_assistants do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description

      # User-configurable: Personality & Language (users can edit)
      t.string :tone, default: 'friendly' # professional, friendly, casual, formal
      t.string :formality, default: 'medium' # high, medium, low
      t.string :empathy_level, default: 'medium' # high, medium, low
      t.string :verbosity, default: 'balanced' # concise, balanced, detailed
      t.string :emoji_usage, default: 'minimal' # none, minimal, moderate
      t.string :greeting_style, default: 'warm' # warm, direct, custom
      t.text :custom_greeting # Custom greeting message
      t.string :language, default: 'en' # Language code (en, ar, fr, etc.)
      t.string :dialect # Dialect code (EG, SA, KW, etc.)
      t.text :personality_description # Free-form personality description

      # Admin-only: Technical configuration (only admins can edit)
      t.text :system_prompt # Base system prompt
      t.text :response_guidelines # How to format responses
      t.text :guardrails # Safety rules
      t.jsonb :admin_config, default: {} # model, temperature, max_tokens, etc.

      t.boolean :active, default: true
      t.timestamps
    end

    add_index :aloo_assistants, %i[account_id name], unique: true
  end

  def create_aloo_assistant_inboxes
    create_table :aloo_assistant_inboxes do |t|
      t.references :aloo_assistant, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true, index: false
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :aloo_assistant_inboxes, :inbox_id, unique: true, name: 'index_aloo_assistant_inboxes_on_inbox_unique'
  end

  def create_aloo_documents
    create_table :aloo_documents do |t|
      t.references :aloo_assistant, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true
      t.string :title
      t.string :source_type, null: false # file (v1 only; website, notion in v2)
      t.string :source_url
      t.text :content
      t.jsonb :metadata, default: {}
      t.integer :status, default: 0 # pending, processing, available, failed, unsupported
      t.string :error_message
      t.timestamps
    end
  end

  def create_aloo_embeddings
    create_table :aloo_embeddings do |t|
      t.references :aloo_assistant, null: false, foreign_key: true, index: true
      t.references :aloo_document, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true
      t.text :content, null: false
      t.text :question # Optional Q&A format
      t.vector :embedding, limit: 1536 # Aloo::EMBEDDING_DIMENSION - text-embedding-3-small
      t.jsonb :metadata, default: {}
      t.integer :status, default: 0 # pending, approved, rejected
      t.timestamps
    end
  end

  def create_aloo_traces
    create_table :aloo_traces do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :aloo_assistant, foreign_key: true, index: true
      t.references :conversation, foreign_key: true, index: true
      t.string :trace_type, null: false # agent_call, search, tool_execution, embedding
      t.string :agent_name
      t.string :request_id # For correlation
      t.jsonb :input_data, default: {}
      t.jsonb :output_data, default: {}
      t.integer :input_tokens
      t.integer :output_tokens
      t.integer :duration_ms
      t.boolean :success, default: true
      t.string :error_message
      t.timestamps
    end

    add_index :aloo_traces, :trace_type
    add_index :aloo_traces, :request_id
  end

  def create_aloo_conversation_contexts
    create_table :aloo_conversation_contexts do |t|
      t.references :conversation, null: false, foreign_key: true, index: { unique: true }
      t.references :aloo_assistant, null: false, foreign_key: true
      t.jsonb :context_data, default: {}
      t.jsonb :tool_history, default: []
      t.integer :message_count, default: 0
      t.integer :input_tokens, default: 0
      t.integer :output_tokens, default: 0
      t.decimal :total_cost, precision: 10, scale: 6, default: 0
      t.timestamps
    end
  end

  def create_aloo_memories
    create_table :aloo_memories do |t|
      t.references :aloo_assistant, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true
      t.references :contact, foreign_key: true, index: true
      t.references :conversation, foreign_key: true, index: true

      # Memory content
      t.string :memory_type, null: false # correction, decision, preference, insight, commitment, gap, faq, procedure
      t.text :content, null: false # The actual memory
      t.text :source_excerpt # Verbatim excerpt from conversation
      t.text :context # Additional context

      # Entities for hybrid search
      t.string :entities, array: true, default: [] # ['contact:123', 'product:widget']
      t.string :topics, array: true, default: [] # ['returns', 'shipping']

      # Ranking signals
      t.vector :embedding, limit: 1536 # Aloo::EMBEDDING_DIMENSION
      t.float :confidence, default: 0.7
      t.integer :observation_count, default: 1
      t.datetime :last_observed_at

      # Feedback tracking
      t.integer :helpful_count, default: 0
      t.integer :not_helpful_count, default: 0
      t.boolean :flagged_for_review, default: false

      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :aloo_memories, :memory_type
    add_index :aloo_memories, :entities, using: :gin
    add_index :aloo_memories, :topics, using: :gin
    add_index :aloo_memories, :confidence
    add_index :aloo_memories, :last_observed_at
  end

  def create_aloo_message_feedbacks
    create_table :aloo_message_feedbacks do |t|
      t.references :message, null: false, foreign_key: true, index: true
      t.references :aloo_memory, foreign_key: true, index: true
      t.references :user, foreign_key: true
      t.string :feedback_type, null: false # helpful, not_helpful
      t.text :comment
      t.timestamps
    end
  end
end
