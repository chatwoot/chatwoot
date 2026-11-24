module SearchIndexing::Conversations
  BATCH_SIZE = 500

  def self.enabled?(account)
    ChatwootApp.advanced_search_allowed? && account&.feature_enabled?('advanced_search_conversations')
  end

  def self.enqueue(account_id, ids, cleanup: false)
    return unless ChatwootApp.advanced_search_allowed?

    ActiveRecord.after_all_transactions_commit do
      next unless cleanup || enabled?(Account.find_by(id: account_id))

      Conversation.search_index.reindex_queue.push(ids)
    end
  end

  def self.refresh_contact(contact, cleanup: false)
    return unless ChatwootApp.advanced_search_allowed?
    return unless cleanup || enabled?(contact.account)

    SearchIndexing::ContactRefreshJob.perform_later(contact.account_id, contact.id)
  end

  def self.setup!
    index = Conversation.search_index
    index.create(index.index_options) unless index.exists?
  end
end
