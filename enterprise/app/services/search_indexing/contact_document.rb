class SearchIndexing::ContactDocument < SearchIndexing::Document
  ENTITY = 'contacts'.freeze
  SCHEMA_VERSION = 1
  INDEXING_FEATURE = 'contact_search_indexing'.freeze
  SEARCH_FIELDS = %w[name email phone_number identifier].freeze
  INDEXED_ATTRIBUTES = (SEARCH_FIELDS + %w[contact_type last_activity_at created_at]).freeze

  def self.scope(account_id)
    Contact.joins(:account).where(account_id: account_id)
  end

  def records(ids)
    self.class.scope(account_id).where(id: ids)
  end

  def serialize(contact)
    contact.attributes.slice(*INDEXED_ATTRIBUTES, 'id', 'account_id').merge(
      'identifier_case_sensitive' => contact.identifier,
      'resolved' => [contact.email, contact.phone_number, contact.identifier].any?(&:present?)
    )
  end

  def properties
    SEARCH_FIELDS.index_with { { type: 'text', analyzer: 'substring' } }.merge(
      id: { type: 'long' }, contact_type: { type: 'keyword' }, resolved: { type: 'boolean' },
      identifier_case_sensitive: { type: 'text', analyzer: 'substring_sensitive' },
      created_at: { type: 'date' }, last_activity_at: { type: 'date' }
    )
  end

  def mapping
    super.merge(settings: self.class.analysis_settings)
  end

  def self.analysis_settings
    {
      analysis: {
        tokenizer: { substring: { type: 'ngram', min_gram: 3, max_gram: 3 } },
        analyzer: {
          substring: { type: 'custom', tokenizer: 'substring', filter: ['lowercase'] },
          substring_sensitive: { type: 'custom', tokenizer: 'substring' }
        }
      }
    }
  end
end
