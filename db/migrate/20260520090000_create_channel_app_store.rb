class CreateChannelAppStore < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_app_store do |t|
      t.bigint :account_id, null: false
      t.string :app_id, null: false
      t.string :bundle_id
      t.string :app_name
      t.string :issuer_id, null: false
      t.string :key_id, null: false
      t.text :private_key, null: false
      t.jsonb :provider_config, null: false, default: {}
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :channel_app_store, [:account_id, :app_id], unique: true
  end
end
