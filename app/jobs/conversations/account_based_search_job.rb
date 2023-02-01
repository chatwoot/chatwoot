class Conversations::AccountBasedSearchJob < ApplicationJob
  queue_as :async_database_migration

  def perform(account_id)
    rebuild_contact_pg_search_documents(account_id)
    rebuild_conversation_pg_search_documents(account_id)
    rebuild_message_pg_search_documents(account_id)
  end

  def rebuild_contact_pg_search_documents(account_id)
    ActiveRecord::Base.connection.execute <<~SQL.squish
      INSERT INTO pg_search_documents (searchable_type, searchable_id, content, account_id, created_at, updated_at)
        SELECT 'Contact' AS searchable_type,
                contacts.id AS searchable_id,
                QUOTE_LITERAL(CONCAT_WS(' ', contacts.id, contacts.email, contacts.name, contacts.phone_number, contacts.account_id)) AS content,
                contacts.account_id::int AS account_id,
                now() AS created_at,
                now() AS updated_at
        FROM contacts
        INNER JOIN conversations
          ON conversations.contact_id = contacts.id
        WHERE contacts.account_id = #{account_id}
    SQL
  end

  def rebuild_conversation_pg_search_documents(account_id)
    ActiveRecord::Base.connection.execute <<~SQL.squish
      INSERT INTO pg_search_documents (searchable_type, searchable_id, content, account_id, created_at, updated_at)
        SELECT 'Conversation' AS searchable_type,
                conversations.id AS searchable_id,
                QUOTE_LITERAL(CONCAT_WS(' ', conversations.display_id, contacts.email, contacts.name, contacts.phone_number, conversations.account_id)) AS content,
                conversations.account_id::int AS account_id,
                now() AS created_at,
                now() AS updated_at
        FROM conversations
        INNER JOIN contacts
          ON conversations.contact_id = contacts.id
        WHERE conversations.account_id = #{account_id}
    SQL
  end

  def rebuild_message_pg_search_documents(account_id)
    ActiveRecord::Base.connection.execute <<~SQL.squish
      INSERT INTO pg_search_documents (searchable_type, searchable_id, content, account_id, created_at, updated_at)
        SELECT 'Message' AS searchable_type,
                messages.id AS searchable_id,
                QUOTE_LITERAL(LEFT(messages.content, 500000)) AS content,
                messages.account_id::int AS account_id,
                now() AS created_at,
                now() AS updated_at
        FROM messages
        WHERE messages.account_id = #{account_id}
    SQL
  end
end
