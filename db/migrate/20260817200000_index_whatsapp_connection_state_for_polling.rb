# The connection-check schedulers find channels to poll with
# `provider_connection->>'connection' = 'open'`, and no GIN index can serve that: jsonb_ops
# indexes containment and key existence, not the value an expression pulls out. The
# existing GIN index on the column only ever narrowed rows by its own partial predicate
# and left the equality as a heap filter, so widening it to the session providers would
# have added write overhead on a column that changes on every QR rotation, for nothing.
# This indexes the expression the query actually asks for.
#
# Concurrent in both directions: a plain CREATE or DROP INDEX takes a lock that queues
# every read and write on channel_whatsapp behind whatever transaction already holds it.
class IndexWhatsappConnectionStateForPolling < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  INDEX = 'index_channel_whatsapp_connection_state'.freeze

  def up
    add_index :channel_whatsapp, "((provider_connection ->> 'connection'))",
              where: "provider IN ('baileys', 'zapi', 'native', 'uazapi')",
              name: INDEX, algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_index :channel_whatsapp, name: INDEX, if_exists: true, algorithm: :concurrently
  end
end
