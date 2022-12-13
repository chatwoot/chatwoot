module MultiSearchableHelpers
  extend ActiveSupport::Concern

  included do
    PgSearch.multisearch_options = {
      using: {
        # trigram: {},
        tsearch: {
          prefix: true,
          any_word: true,
          normalization: 3
        }
      }
    }

    def update_contact_search_document
      return if contact_pg_search_record.present?

      initialize_contact_pg_search_record.update!(
        content: "#{contact.id} #{contact.email} #{contact.name} #{contact.phone_number} #{contact.account_id}",
        conversation_id: id
      )
    end
  end

  def contact_pg_search_record
    contacts_pg_search_records.find_by(conversation_id: id)
  end

  def initialize_contact_pg_search_record
    record = contacts_pg_search_records.find_by(conversation_id: nil)

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
