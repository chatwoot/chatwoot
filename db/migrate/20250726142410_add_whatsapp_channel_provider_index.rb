class AddWhatsappChannelProviderIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :channel_whatsapp, :provider_connection,
              using: :gin,
              where: "provider = 'baileys'",
              name: 'index_channel_whatsapp_baileys_connection'
  end
end
