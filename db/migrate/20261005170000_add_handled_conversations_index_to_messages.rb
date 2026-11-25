# Backs Reports::HandledConversations. A month of a busy account is over a million
# outgoing messages, and without it the agents report scans the heap for every one of
# them and runs past the statement timeout. The predicate is Reports::HandledConversations::PREDICATE,
# copied rather than referenced so this migration keeps meaning the same thing whatever
# the constant becomes; the spec on the query plan fails when the two drift apart.
#
# On a large installation, create it by hand with the same statement before deploying,
# so the migration finds it valid and returns at once.
class AddHandledConversationsIndexToMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  INDEX = 'index_messages_on_handled_conversations'.freeze

  def up
    build_index unless index_state == :valid
    vacuum_messages_as_they_arrive
  end

  def down
    execute('ALTER TABLE messages RESET (autovacuum_vacuum_insert_scale_factor)') if insert_vacuum_supported?
    remove_index :messages, name: INDEX, algorithm: :concurrently, if_exists: true
  end

  private

  def build_index
    # A concurrent build that was interrupted leaves an invalid index behind, which
    # Postgres keeps updating and never reads. Skipping it would mark the migration done
    # with no usable index, so it is dropped and built again.
    remove_index :messages, name: INDEX, algorithm: :concurrently if index_state == :invalid

    # The build reads the whole table, which takes minutes on a large installation and
    # would hit the connection's statement timeout (14s by default) halfway through.
    without_statement_timeout do
      add_index :messages, [:account_id, :created_at],
                name: INDEX,
                include: [:sender_type, :sender_id, :conversation_id, :inbox_id],
                where: 'message_type = 1 AND private = false ' \
                       "AND ((content_attributes#>>'{}')::jsonb->>'is_reaction' = 'true') IS NOT TRUE " \
                       "AND COALESCE((content_attributes#>>'{}')::jsonb->>'automation_rule_id', '') = '' " \
                       "AND COALESCE(additional_attributes->>'campaign_id', '') = '' " \
                       "AND (sender_type = 'User' OR COALESCE((content_attributes#>>'{}')::jsonb->>'external_echo', '') NOT IN ('', 'false'))",
                algorithm: :concurrently
    end
  end

  # The index is answered from alone only for pages the visibility map marks all-visible,
  # and only a vacuum marks them. By default an insert-mostly table is vacuumed every 20%
  # of growth: on fifteen million messages that is three million new ones, about two
  # months on a busy account, so the month the reports read is exactly the one left
  # unmarked and every row goes back to the heap. 1% keeps the recent pages marked.
  # The setting exists from Postgres 13 on.
  def vacuum_messages_as_they_arrive
    execute('ALTER TABLE messages SET (autovacuum_vacuum_insert_scale_factor = 0.01)') if insert_vacuum_supported?
  end

  def insert_vacuum_supported?
    connection.database_version >= 130_000
  end

  def index_state
    valid = select_value(<<~SQL.squish)
      SELECT i.indisvalid FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid WHERE c.relname = '#{INDEX}'
    SQL
    return :missing if valid.nil?

    valid ? :valid : :invalid
  end

  def without_statement_timeout
    previous = select_value('SHOW statement_timeout')
    execute('SET statement_timeout = 0')
    yield
  ensure
    execute("SET statement_timeout = #{connection.quote(previous)}") if previous
  end
end
