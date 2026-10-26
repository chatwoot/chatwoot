class CreateCaptainMcpServers < ActiveRecord::Migration[7.2]
  def change
    create_table :captain_mcp_servers do |t|
      t.bigint :account_id, null: false, index: true
      t.bigint :assistant_id, null: false
      t.text :url, null: false
      t.string :name, null: false
      t.string :auth_type, null: false, default: 'none'
      t.string :auth_header
      t.jsonb :auth_config, default: {}
      t.jsonb :server_info, null: false, default: {}
      t.jsonb :tools, null: false, default: []
      t.string :status, null: false, default: 'active'
      t.datetime :last_checked_at
      t.text :last_error
      t.datetime :tools_changed_at
      t.boolean :enabled, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps
      t.index [:assistant_id, :url], unique: true
    end
  end
end
