class CreateChannelZaloOa < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_zalo_oa do |t|
      t.integer :account_id, null: false
      t.string :oa_id, null: false
      t.string :oa_name
      t.string :app_id, null: false
      t.text :app_secret, null: false
      t.text :oa_secret_key
      t.text :access_token
      t.text :refresh_token
      t.datetime :token_expires_at

      t.timestamps
    end

    add_index :channel_zalo_oa, :oa_id, unique: true
  end
end
