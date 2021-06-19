
class CreateChannelGupshup < ActiveRecord::Migration[6.0]
  def change
    create_table :channel_gupshup do |t|
      t.string :account_id, null: false
      t.string :app, null: false
      t.string :apikey, null: false
      t.integer :phone_number, null: false
      t.timestamps
    end
  end
end
