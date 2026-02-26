class CreateCaptainMcpServers < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_mcp_servers, if_not_exists: true do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :url, null: false
      t.string :auth_type, default: 'none'
      t.text :auth_config
      t.boolean :enabled, default: true, null: false
      t.string :status, default: 'disconnected'
      t.text :last_error
      t.datetime :last_connected_at
      t.jsonb :cached_tools, default: []
      t.datetime :cache_refreshed_at

      t.timestamps
    end

    add_index :captain_mcp_servers, [:account_id, :slug], unique: true, if_not_exists: true
    add_index :captain_mcp_servers, [:account_id, :enabled], if_not_exists: true
  end
end
