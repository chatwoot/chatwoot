class AddOauth2AndPaymentFieldsToAppleMessagesForBusiness < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_apple_messages_for_business, :oauth2_providers, :jsonb, default: {}
    add_column :channel_apple_messages_for_business, :auth_sessions, :jsonb, default: {}
    add_column :channel_apple_messages_for_business, :payment_processors, :jsonb, default: {}
    add_column :channel_apple_messages_for_business, :merchant_certificates, :text
    add_column :channel_apple_messages_for_business, :payment_settings, :jsonb, default: {}

    add_index :channel_apple_messages_for_business, :oauth2_providers, using: :gin
    add_index :channel_apple_messages_for_business, :payment_processors, using: :gin
    add_index :channel_apple_messages_for_business, :payment_settings, using: :gin
  end
end