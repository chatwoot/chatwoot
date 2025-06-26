class CreateChannelZalos < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_zalos do |t|
      t.timestamps
      t.text :access_token, null: false
      t.text :refresh_token, null: false
      t.datetime :expires_at, null: false
      t.integer :account_id, null: false, index: true
      t.string :oa_id, null: false
      t.jsonb :meta, null: false
    end
  end
end
