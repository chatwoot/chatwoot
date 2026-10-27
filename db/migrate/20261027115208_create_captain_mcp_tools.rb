class CreateCaptainMcpTools < ActiveRecord::Migration[7.2]
  def change
    create_table :captain_mcp_tools do |t|
      t.bigint :account_id, null: false, index: true
      t.bigint :mcp_server_id, null: false
      t.string :name, null: false
      t.string :captain_name, null: false
      t.jsonb :approved_definition, null: false, default: {}
      t.string :approved_digest, null: false
      t.jsonb :param_sources, null: false, default: {}
      t.jsonb :settings, null: false, default: {}
      t.boolean :enabled, null: false, default: true
      t.timestamps
      t.index [:mcp_server_id, :name], unique: true
      t.index :captain_name, unique: true
    end
  end
end
