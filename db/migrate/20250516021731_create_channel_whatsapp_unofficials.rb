class CreateChannelWhatsappUnofficials < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_whatsapp_unofficials do |t|
      t.string :phone_number, null: false
      t.string :webhook_url
      t.integer :account_id, null: false

      t.timestamps
    end

    add_index :channel_whatsapp_unofficials, :account_id
    add_index :channel_whatsapp_unofficials, :phone_number, unique: true
  end
end
