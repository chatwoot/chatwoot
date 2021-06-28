
class CreateChannelGupshup < ActiveRecord::Migration[6.0]
  def change
    create_table :channel_gupshup do |t|
      t.integer :account_id, null: false
      t.string :app, null: false
      t.string :apikey, null: false
      t.string :phone_number, null: false
      t.timestamps
    end
    add_index :channel_gupshup, :phone_number
  end
end
