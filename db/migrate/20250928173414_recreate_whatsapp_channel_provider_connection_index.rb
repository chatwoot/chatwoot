class RecreateWhatsappChannelProviderConnectionIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    remove_index :channel_whatsapp, name: 'index_channel_whatsapp_baileys_connection', if_exists: true

    add_index :channel_whatsapp, :provider_connection,
              using: :gin,
              where: "provider IN ('baileys', 'zapi')",
              name: 'index_channel_whatsapp_provider_connection',
              algorithm: :concurrently
  end

  def down
    remove_index :channel_whatsapp, name: 'index_channel_whatsapp_provider_connection', if_exists: true

    add_index :channel_whatsapp, :provider_connection,
              using: :gin,
              where: "provider = 'baileys'",
              name: 'index_channel_whatsapp_baileys_connection',
              algorithm: :concurrently
  end
end
