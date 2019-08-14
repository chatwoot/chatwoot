class CreateTelegramBots < ActiveRecord::Migration[5.0]
  def change
    create_table :telegram_bots do |t|
      t.string :name
      t.string :auth_key
      t.integer :account_id
      t.timestamps
    end
  end
end
