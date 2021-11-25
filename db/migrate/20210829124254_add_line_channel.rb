class AddLineChannel < ActiveRecord::Migration[6.1]
  def change
    create_table :channel_line do |t|
      t.integer :account_id, null: false
      t.string :line_channel_id, null: false, index: { unique: true }
      t.string :line_channel_secret, null: false
      t.string :line_channel_token, null: false
      t.timestamps
    end
  end
end
