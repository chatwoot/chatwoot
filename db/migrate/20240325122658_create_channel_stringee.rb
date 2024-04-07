class CreateChannelStringee < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_stringee do |t|
      t.integer :account_id, null: false
      t.string :phone_number, null: false
      t.string :queue_id, null: false
      t.string :number_id, null: false
      t.index :phone_number, name: 'index_channel_stringee_on_phone_number', unique: true
      t.index [:phone_number, :account_id], name: 'index_channel_stringee_on_phone_number_and_account_id', unique: true
      t.timestamps
    end
  end
end
