module Enterprise::SearchIndexing::Conversation
  extend ActiveSupport::Concern

  included do
    after_commit :enqueue_conversation_search_document, on: [:create, :update]
    after_destroy_commit :remove_conversation_search_document
  end

  private

  def enqueue_conversation_search_document
    return unless previous_changes.keys.intersect?(::SearchIndexing::ConversationDocument::INDEXED_ATTRIBUTES) ||
                  previously_new_record? || search_subject_changed?

    ::SearchIndexing::Producer.enqueue(entity: 'conversations', account_id: account_id, ids: [id])
  end

  def search_subject_changed?
    before, after = previous_changes['additional_attributes']
    before.to_h['mail_subject'] != after.to_h['mail_subject']
  end

  def remove_conversation_search_document
    ::SearchIndexing::Producer.enqueue(entity: 'conversations', account_id: account_id, ids: [id], cleanup: true)
  end
end
