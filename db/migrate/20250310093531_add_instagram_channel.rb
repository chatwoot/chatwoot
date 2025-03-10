class AddInstagramChannel < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_instagram do |t|
      t.string :access_token, null: false
      t.string :refresh_token
      t.datetime :expires_at, null: false
      t.integer :account_id, null: false
      t.string :instagram_id, null: false
      t.timestamps
    end
  end
end
