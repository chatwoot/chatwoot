class AddCommonWhatsappChannel < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_common_whatsapp do |t|
      t.integer :account_id, null: false
      t.string :phone_number, null: false, index: { unique: true }
      t.string :token, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
