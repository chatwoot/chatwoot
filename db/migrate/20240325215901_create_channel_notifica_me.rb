class CreateChannelNotificaMe < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_notifica_me do |t|
      t.string :channel_id, null: false
      t.string :channel_type, null: false
      t.string :channel_token, null: false
      t.integer :account_id, null: false
      t.index [:channel_id, :channel_type, :channel_token], name: :index_channel_notifica_me, unique: true

      t.timestamps
    end
  end
end
