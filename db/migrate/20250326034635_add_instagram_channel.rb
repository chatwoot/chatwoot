class AddInstagramChannel < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_instagram do |t|
      t.string :access_token, null: false
      t.datetime :expires_at, null: false
      t.integer :account_id, null: false
      t.string :instagram_id, null: false
      t.timestamps
    end

    add_index :channel_instagram, :instagram_id, unique: true
  end
end
