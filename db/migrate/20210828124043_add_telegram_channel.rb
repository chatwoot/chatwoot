class AddTelegramChannel < ActiveRecord::Migration[6.1]
  def change
    create_table :channel_telegram do |t|
      t.string :bot_name
      t.integer :account_id, null: false
      t.string :bot_token, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
