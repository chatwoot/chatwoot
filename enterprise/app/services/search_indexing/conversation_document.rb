class SearchIndexing::ConversationDocument
  INDEXED_ATTRIBUTES = %w[contact_id inbox_id display_id created_at last_activity_at].freeze

  def self.index_name
    "chatwoot_#{Rails.env}_conversations_searchkick_v1"
  end

  def self.serialize(conversation)
    conversation.attributes.slice(*INDEXED_ATTRIBUTES, 'id', 'account_id').merge(
      'display_id_text' => conversation.display_id.to_s,
      'mail_subject' => conversation.additional_attributes['mail_subject']
    )
  end

  def self.mappings
    { dynamic: false, properties: {
      id: { type: 'long' }, account_id: { type: 'long' }, contact_id: { type: 'long' }, inbox_id: { type: 'long' }, display_id: { type: 'long' },
      display_id_text: { type: 'text', analyzer: 'substring' }, mail_subject: { type: 'text', analyzer: 'substring' },
      created_at: { type: 'date' }, last_activity_at: { type: 'date' }
    } }
  end

  def self.settings
    { analysis: {
      tokenizer: { substring: { type: 'ngram', min_gram: 3, max_gram: 3 } },
      analyzer: { substring: { type: 'custom', tokenizer: 'substring', filter: ['lowercase'] } }
    } }
  end
end
