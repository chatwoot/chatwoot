class CreateChannelWhatsappZapi < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_whatsapp_zapi do |t|
      t.string :phone_number, null: false
      t.string :instance_id, null: false
      t.string :token, null: false
      t.string :api_url, null: false
      t.string :security_token, null: false
      t.jsonb :provider_config, default: {}
      t.references :account, null: false, foreign_key: true
      t.timestamps
    end
    add_index :channel_whatsapp_zapi, :phone_number, unique: true
  end
end
