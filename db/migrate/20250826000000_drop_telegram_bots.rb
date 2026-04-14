class DropTelegramBots < ActiveRecord::Migration[7.1]
  def change
    drop_table :telegram_bots do |t|
      t.string :name
      t.string :auth_key
      t.integer :account_id
      t.timestamps
    end
  end
end
