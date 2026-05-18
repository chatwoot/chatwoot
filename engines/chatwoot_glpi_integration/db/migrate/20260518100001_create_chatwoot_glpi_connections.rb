class CreateChatwootGlpiConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :chatwoot_glpi_connections do |t|
      t.references :account, null: false,
                   foreign_key: { to_table: :accounts, on_delete: :cascade },
                   index: { unique: true }
      t.string  :base_url,        null: false        # https://glpi.empresa.com
      t.string  :api_path,        null: false, default: '/apirest.php'
      # OAuth2 client_credentials (GLPI 11+)
      t.string  :client_id,       null: false
      t.text    :client_secret,   null: false        # encrypted via Rails encryption
      t.string  :scope,                       default: 'api'
      # Defaults applied when creating tickets
      t.integer :default_entity_id,    null: false, default: 0
      t.integer :default_itil_category_id
      t.integer :default_request_type_id, default: 1
      # Inbound webhook secret (also kept in env, this is per-account)
      t.string  :webhook_secret
      t.boolean :active, null: false, default: true
      t.datetime :last_handshake_at
      t.timestamps
    end
  end
end
