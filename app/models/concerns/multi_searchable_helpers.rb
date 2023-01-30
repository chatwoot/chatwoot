module MultiSearchableHelpers
  extend ActiveSupport::Concern

  included do # rubocop:disable Metrics/BlockLength
    PgSearch.multisearch_options = {
      using: {
        trigram: {
          word_similarity: true,
          threshold: 0.3
        },
        tsearch: { any_word: true }
      }
    }

    def update_contact_search_document
      return if contact_pg_search_record.present?

      initialize_contact_pg_search_record.update!(
        content: "#{contact.id} #{contact.email} #{contact.name} #{contact.phone_number} #{contact.account_id}",
        conversation_id: id,
        inbox_id: inbox_id
      )
    end

    # NOTE: To add multi search records with contacts.name associated to conversation for previously added records.
    # We can not find contacts.name from conversations directly so we added this joins here.
    def self.rebuild_pg_search_documents(account_id)
      return unless name == 'Conversation'

      connection.execute <<~SQL.squish
        INSERT INTO pg_search_documents (searchable_type, searchable_id, content, account_id, conversation_id, inbox_id, created_at, updated_at)
          SELECT 'Conversation' AS searchable_type,
                  conversations.id AS searchable_id,
                  CONCAT_WS(' ', conversations.display_id, contacts.email, contacts.name, contacts.phone_number, conversations.account_id) AS content,
                  conversations.account_id::int AS account_id,
                  conversations.id::int AS conversation_id,
                  conversations.inbox_id::int AS inbox_id,
                  now() AS created_at,
                  now() AS updated_at
          FROM conversations
          INNER JOIN contacts
            ON conversations.contact_id = contacts.id
          WHERE conversations.account_id = #{account_id}
      SQL
    end
  end

  def contact_pg_search_record
    contacts_pg_search_records.find_by(conversation_id: id, inbox_id: inbox_id)
  end

  def initialize_contact_pg_search_record
    record = contacts_pg_search_records.find_by(conversation_id: nil, inbox_id: nil)

    return record if record.present?

    PgSearch::Document.new(
      searchable_type: 'Contact',
      searchable_id: contact_id,
      account_id: account_id
    )
  end

  def contacts_pg_search_records
    PgSearch::Document.where(
      searchable_type: 'Contact',
      searchable_id: contact_id,
      account_id: account_id
    )
  end
end
