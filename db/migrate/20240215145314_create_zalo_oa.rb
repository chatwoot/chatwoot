class CreateZaloOa < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_zalo_oa do |t|
      t.string :oa_access_token, null: false
      t.string :refresh_token, null: false
      t.integer :expires_in, null: false
      t.integer :account_id, null: false
      t.string :oa_id, null: false
      t.index :oa_id, name: 'index_channel_zalo_oa_on_oa_id', unique: true
      t.index :oa_id, :account_id, name: 'index_channel_zalo_oa_on_oa_id_and_account_id', unique: true
      t.timestamps null: false
    end
  end
end
