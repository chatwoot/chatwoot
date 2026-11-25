# Every event the connector publishes is addressed by session id, and the consumer has
# to find the inbox behind it before it can do anything with the event. That lookup runs
# once per event, so it gets its own expression index.
#
# Unique, because the id is the address: two inboxes answering to one would take each
# other's messages, and the lookup has no way to tell which was meant.
class IndexWhatsappSessionId < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_index :channel_whatsapp, "(provider_config->>'session_id')",
              where: "provider IN ('native', 'uazapi')",
              name: 'index_channel_whatsapp_session_id',
              unique: true,
              algorithm: :concurrently
  end

  def down
    remove_index :channel_whatsapp, name: 'index_channel_whatsapp_session_id', if_exists: true, algorithm: :concurrently
  end
end
