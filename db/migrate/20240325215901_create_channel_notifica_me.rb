class CreateChannelNotificaMe < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_notifica_me do |t|
      t.string :notifica_me_id, null: false
      t.string :notifica_me_type, null: false
      t.string :notifica_me_token, null: false
      t.index [:notifica_me_id, :notifica_me_type, :notifica_me_token], name: :index_channel_notifica_me, unique: true
      t.integer :account_id, null: false

      t.timestamps
    end
  end
end
