module Enterprise::SearchIndexing::Contact
  extend ActiveSupport::Concern

  included do
    after_commit :refresh_contact_conversation_documents, on: :update
    after_destroy_commit :remove_contact_conversation_documents
  end

  private

  def refresh_contact_conversation_documents
    return unless previous_changes.keys.intersect?(::SearchIndexing::ConversationDocument::CONTACT_FIELDS)

    ::SearchIndexing::Producer.enqueue(entity: 'contact_conversations', account_id: account_id, ids: [id])
  end

  def remove_contact_conversation_documents
    ::SearchIndexing::Producer.enqueue(entity: 'contact_conversations', account_id: account_id, ids: [id], cleanup: true)
  end
end
