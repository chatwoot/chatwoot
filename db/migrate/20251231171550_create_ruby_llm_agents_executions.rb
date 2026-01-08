# frozen_string_literal: true

class CreateRubyLLMAgentsExecutions < ActiveRecord::Migration[7.1]
  def change
    create_table :ruby_llm_agents_executions do |t|
      # Agent identification
      t.string :agent_type, null: false
      t.string :agent_version, default: "1.0"

      # Model configuration
      t.string :model_id, null: false
      t.string :model_provider
      t.decimal :temperature, precision: 3, scale: 2

      # Timing
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.integer :duration_ms

      # Streaming and finish
      t.boolean :streaming, default: false
      t.integer :time_to_first_token_ms
      t.string :finish_reason

      # Distributed tracing
      t.string :request_id
      t.string :trace_id
      t.string :span_id
      t.bigint :parent_execution_id
      t.bigint :root_execution_id

      # Routing and retries
      t.string :fallback_reason
      t.boolean :retryable
      t.boolean :rate_limited

      # Caching
      t.boolean :cache_hit, default: false
      t.string :response_cache_key
      t.datetime :cached_at

      # Status
      t.string :status, default: "success", null: false

      # Token usage
      t.integer :input_tokens
      t.integer :output_tokens
      t.integer :total_tokens
      t.integer :cached_tokens, default: 0
      t.integer :cache_creation_tokens, default: 0

      # Costs (in dollars, 6 decimal precision)
      t.decimal :input_cost, precision: 12, scale: 6
      t.decimal :output_cost, precision: 12, scale: 6
      t.decimal :total_cost, precision: 12, scale: 6

      # Data (JSONB for PostgreSQL, JSON for others)
      t.jsonb :parameters, null: false, default: {}
      t.jsonb :response, default: {}
      t.jsonb :metadata, null: false, default: {}

      # Error tracking
      t.string :error_class
      t.text :error_message

      # Prompts (for history/changelog)
      t.text :system_prompt
      t.text :user_prompt

      # Tool calls tracking
      t.jsonb :tool_calls, null: false, default: []
      t.integer :tool_calls_count, null: false, default: 0

      t.timestamps
    end

    # Indexes for common queries
    add_index :ruby_llm_agents_executions, :agent_type
    add_index :ruby_llm_agents_executions, :status
    add_index :ruby_llm_agents_executions, :created_at
    add_index :ruby_llm_agents_executions, [:agent_type, :created_at]
    add_index :ruby_llm_agents_executions, [:agent_type, :status]
    add_index :ruby_llm_agents_executions, [:agent_type, :agent_version]
    add_index :ruby_llm_agents_executions, :duration_ms
    add_index :ruby_llm_agents_executions, :total_cost

    # Tracing indexes
    add_index :ruby_llm_agents_executions, :request_id
    add_index :ruby_llm_agents_executions, :trace_id
    add_index :ruby_llm_agents_executions, :parent_execution_id
    add_index :ruby_llm_agents_executions, :root_execution_id

    # Caching index
    add_index :ruby_llm_agents_executions, :response_cache_key

    # Tool calls index
    add_index :ruby_llm_agents_executions, :tool_calls_count

    # Foreign keys for execution hierarchy
    add_foreign_key :ruby_llm_agents_executions, :ruby_llm_agents_executions,
                    column: :parent_execution_id, on_delete: :nullify
    add_foreign_key :ruby_llm_agents_executions, :ruby_llm_agents_executions,
                    column: :root_execution_id, on_delete: :nullify

    # GIN indexes for JSONB columns (PostgreSQL only)
    # Uncomment if using PostgreSQL:
    # add_index :ruby_llm_agents_executions, :parameters, using: :gin
    # add_index :ruby_llm_agents_executions, :metadata, using: :gin
  end
end
