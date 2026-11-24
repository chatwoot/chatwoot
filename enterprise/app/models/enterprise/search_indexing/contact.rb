module Enterprise::SearchIndexing::Contact
  extend ActiveSupport::Concern

  included do
    after_update_commit :refresh_contact_conversation_documents
    after_destroy_commit :remove_contact_conversation_documents
  end

  private

  def refresh_contact_conversation_documents
    return unless previous_changes.keys.intersect?(::SearchIndexing::ConversationDocument::CONTACT_FIELDS)

    ::SearchIndexing::Conversations.refresh_contact(self)
  end

  def remove_contact_conversation_documents
    ::SearchIndexing::Conversations.refresh_contact(self, cleanup: true)
  end
end
