class SearchIndexing::ConversationDocument < SearchIndexing::Document
  ENTITY = 'conversations'.freeze
  SCHEMA_VERSION = 1
  INDEXING_FEATURE = 'conversation_search_indexing'.freeze
  INDEXED_ATTRIBUTES = %w[contact_id inbox_id display_id created_at last_activity_at].freeze

  def self.scope(account_id)
    Conversation.joins(:account, :contact).where(account_id: account_id)
  end

  def records(ids)
    self.class.scope(account_id).where(id: ids).preload(:contact)
  end

  def serialize(conversation)
    conversation.attributes.slice(*INDEXED_ATTRIBUTES, 'id', 'account_id').merge(
      'display_id_text' => conversation.display_id.to_s,
      'contact' => conversation.contact.attributes.slice(*SearchIndexing::ContactDocument::SEARCH_FIELDS)
    )
  end

  def properties
    {
      id: { type: 'long' }, contact_id: { type: 'long' }, inbox_id: { type: 'long' }, display_id: { type: 'long' },
      display_id_text: { type: 'text', analyzer: 'substring' },
      created_at: { type: 'date' }, last_activity_at: { type: 'date' },
      contact: { properties: SearchIndexing::ContactDocument::SEARCH_FIELDS.index_with { { type: 'text', analyzer: 'substring' } } }
    }
  end

  def mapping
    super.merge(settings: SearchIndexing::ContactDocument.analysis_settings)
  end
end
