class CreateChannelXmpp < ActiveRecord::Migration[6.1]
  def change
    create_table :channel_xmpp do |t|
      t.string :jid, null: false
      t.string :password, null: false
      t.string :last_mam_id
      t.belongs_to :account
      t.timestamps
    end
  end
end
