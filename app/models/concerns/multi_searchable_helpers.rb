module MultiSearchableHelpers
  extend ActiveSupport::Concern

  included do
    PgSearch.multisearch_options = {
      using: {
        tsearch: {
          prefix: true,
          any_word: true,
          normalization: 3
        }
      }
    }

    def self.rebuild_pg_search_documents
      return unless name == 'Contact'

      connection.execute <<~SQL.squish
        INSERT INTO pg_search_documents (searchable_type, searchable_id, content, account_id, conversation_id, created_at, updated_at)
          SELECT 'Contact' AS searchable_type,
                  contacts.id AS searchable_id,
                  CONCAT_WS(' ', contacts.email, contacts.name, contacts.phone_number, contacts.id, contacts.account_id) AS content,
                  contacts.account_id::int AS account_id,
                  conversations.id AS conversation_id,
                  now() AS created_at,
                  now() AS updated_at
          FROM contacts
          INNER JOIN conversations
            ON conversations.contact_id = contacts.id
      SQL
    end

    def update_contact_search_document
      PgSearch::Document.create({ searchable_type: 'Contact', searchable_id: contact_id, conversation_id: id, account_id: account_id,
                                  content: "#{contact.email} #{contact.name} #{contact.phone_number} #{contact.id}" })
    end
  end
end
