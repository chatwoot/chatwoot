module Enterprise::SearchIndexing::Conversation
  extend ActiveSupport::Concern

  included do
    # Explicit producers gate queueing by account and cover callback-bypassing imports.
    searchkick callbacks: false, batch_size: ::SearchIndexing::Conversations::BATCH_SIZE,
               index_name: -> { ::SearchIndexing::ConversationDocument.index_name },
               mappings: ::SearchIndexing::ConversationDocument.mappings, settings: ::SearchIndexing::ConversationDocument.settings
    scope :search_import, -> { includes(:account) }

    after_commit :enqueue_conversation_search_document, on: [:create, :update]
    after_destroy_commit :remove_conversation_search_document
  end

  def search_data
    ::SearchIndexing::ConversationDocument.serialize(self)
  end

  def should_index?
    ::SearchIndexing::Conversations.enabled?(account)
  end

  private

  def enqueue_conversation_search_document
    before, after = previous_changes['additional_attributes']
    return unless previously_new_record? || previous_changes.keys.intersect?(::SearchIndexing::ConversationDocument::INDEXED_ATTRIBUTES) ||
                  before.to_h['mail_subject'] != after.to_h['mail_subject']

    ::SearchIndexing::Conversations.enqueue(account_id, [id])
  end

  def remove_conversation_search_document
    ::SearchIndexing::Conversations.enqueue(account_id, [id], cleanup: true)
  end
end
