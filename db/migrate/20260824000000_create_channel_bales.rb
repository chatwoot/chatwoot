class CreateChannelBales < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_bales do |t|
      t.string :bot_name
      t.integer :account_id, null: false
      t.string :bot_token, null: false
      t.timestamps
    end
    add_index :channel_bales, :bot_token, unique: true
  end
end
