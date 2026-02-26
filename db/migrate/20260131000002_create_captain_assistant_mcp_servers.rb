class CreateCaptainAssistantMcpServers < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_assistant_mcp_servers do |t|
      t.references :captain_assistant, null: false, index: true
      t.references :captain_mcp_server, null: false, index: true
      t.jsonb :tool_filters, default: {}
      t.boolean :enabled, default: true, null: false

      t.timestamps
    end

    add_index :captain_assistant_mcp_servers,
              [:captain_assistant_id, :captain_mcp_server_id],
              unique: true,
              name: 'idx_captain_assistant_mcp_server_unique'
  end
end
