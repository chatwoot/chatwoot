class CreateChannelAppleMessagesForBusiness < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_apple_messages_for_business do |t|
      t.string :msp_id, null: false
      t.string :business_id, null: false
      t.text :secret, null: false
      t.string :merchant_id
      t.text :apple_pay_merchant_cert
      t.string :webhook_url
      t.string :imessage_extension_bid, default: 'com.apple.messages.MSMessageExtensionBalloonPlugin:0000000000:com.apple.icloud.apps.messages.business.extension'
      t.jsonb :provider_config, default: {}
      t.integer :account_id, null: false
      t.timestamps
    end

    add_index :channel_apple_messages_for_business, :msp_id, unique: true
    add_index :channel_apple_messages_for_business, :business_id, unique: true
    add_index :channel_apple_messages_for_business, :account_id
  end
end
