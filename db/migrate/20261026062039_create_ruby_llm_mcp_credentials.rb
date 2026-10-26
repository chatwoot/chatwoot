# RubyLLM keeps MCP OAuth credentials here. The columns follow the RubyLLM install template.
class CreateRubyLlmMcpCredentials < ActiveRecord::Migration[7.2]
  def change
    create_table :ruby_llm_mcp_credentials do |t|
      t.references :owner, polymorphic: true, index: true
      t.string :key, null: false
      t.text :data
      t.timestamps
    end

    add_index :ruby_llm_mcp_credentials, :key, unique: true
  end
end
