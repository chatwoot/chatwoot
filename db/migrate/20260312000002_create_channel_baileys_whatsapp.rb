class CreateChannelBaileysWhatsapp < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_baileys_whatsapp do |t|
      t.integer :account_id, null: false
      t.string :phone_number
      t.string :session_id, null: false
      t.string :session_status, default: 'disconnected'
      t.jsonb :provider_config, default: {}
      t.datetime :last_connected_at
      t.timestamps
    end

    add_index :channel_baileys_whatsapp, :account_id
    add_index :channel_baileys_whatsapp, :session_id, unique: true
    add_index :channel_baileys_whatsapp, :phone_number
  end
end
