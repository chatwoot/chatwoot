module Enterprise::SearchIndexing::Contact
  extend ActiveSupport::Concern

  included do
    after_commit :enqueue_contact_search_document, on: [:create, :update]
    after_destroy_commit :remove_contact_search_document
  end

  private

  def enqueue_contact_search_document
    return unless previous_changes.keys.intersect?(::SearchIndexing::ContactDocument::INDEXED_ATTRIBUTES) || previously_new_record?

    ::SearchIndexing::Producer.enqueue(entity: 'contacts', account_id: account_id, ids: [id])
  end

  def remove_contact_search_document
    ::SearchIndexing::Producer.enqueue(entity: 'contacts', account_id: account_id, ids: [id], cleanup: true)
  end
end
