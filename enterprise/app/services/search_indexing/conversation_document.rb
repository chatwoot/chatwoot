class SearchIndexing::ConversationDocument < SearchIndexing::Document
  ENTITY = 'conversations'.freeze
  SCHEMA_VERSION = 2
  INDEXING_FEATURE = 'conversation_search_indexing'.freeze
  CONTACT_FIELDS = %w[name email phone_number identifier].freeze
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
      'mail_subject' => conversation.additional_attributes['mail_subject'],
      'contact' => conversation.contact.attributes.slice(*CONTACT_FIELDS)
    )
  end

  def properties
    {
      id: { type: 'long' }, contact_id: { type: 'long' }, inbox_id: { type: 'long' }, display_id: { type: 'long' },
      display_id_text: { type: 'text', analyzer: 'substring' }, mail_subject: { type: 'text', analyzer: 'substring' },
      created_at: { type: 'date' }, last_activity_at: { type: 'date' },
      contact: { properties: CONTACT_FIELDS.index_with { { type: 'text', analyzer: 'substring' } } }
    }
  end

  def mapping
    super.merge(settings: {
                  analysis: {
                    tokenizer: { substring: { type: 'ngram', min_gram: 3, max_gram: 3 } },
                    analyzer: { substring: { type: 'custom', tokenizer: 'substring', filter: ['lowercase'] } }
                  }
                })
  end
end
