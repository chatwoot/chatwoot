class CreateWechatKfChannels < ActiveRecord::Migration[7.1]
  def change
    create_table :wechat_kf_integrations do |t|
      t.references :account, type: :integer, null: false, foreign_key: true
      t.string :corp_id, null: false
      t.text :corp_secret, null: false
      t.text :callback_token, null: false
      t.text :encoding_aes_key, null: false
      t.timestamps
    end
    add_index :wechat_kf_integrations, :corp_id, unique: true

    create_table :channel_wechat_kf do |t|
      t.references :account, type: :integer, null: false, foreign_key: true
      t.references :wechat_kf_integration, null: false, foreign_key: true
      t.string :open_kfid, null: false
      t.text :sync_cursor
      t.timestamps
    end
    add_index :channel_wechat_kf, :open_kfid, unique: true
  end
end
