# frozen_string_literal: true

class CreateAgentTools < ActiveRecord::Migration[7.1]
  def change
    create_table :agent_tools do |t|
      t.references :ai_agent, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true

      t.string :name, null: false
      t.text :description                              # shown to LLM for tool selection
      t.integer :tool_type, null: false, default: 0    # enum: http, handoff, built_in

      # HTTP tool configuration
      t.string :http_method, default: 'POST'           # GET, POST, PUT, PATCH, DELETE
      t.string :url_template                           # Liquid template URL
      t.jsonb :headers_template, default: {}           # Liquid template headers
      t.text :body_template                            # Liquid template body
      t.jsonb :parameters_schema, default: {}          # JSON Schema for tool parameters (sent to LLM)

      # Authentication
      t.string :auth_type                              # none, bearer, api_key, basic
      t.string :auth_token                             # encrypted token/key

      t.boolean :active, default: true
      t.jsonb :config, default: {}                     # extra settings (timeout, retry, etc.)

      t.timestamps
    end

    add_index :agent_tools, [:ai_agent_id, :active]
    add_index :agent_tools, :tool_type
  end
end
