class CreateChannelZaloOa < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_zalo_oa do |t|
      t.string :oa_id, null: false
      t.string :access_token, null: false
      t.string :refresh_token
      t.integer :account_id, null: false
      t.timestamps
    end

    add_index :channel_zalo_oa, :oa_id, unique: true
  end
end
