module SearchIndexing::Registry
  # Register projections as their lifecycle writers are introduced.
  DOCUMENTS = { 'contacts' => 'SearchIndexing::ContactDocument', 'conversations' => 'SearchIndexing::ConversationDocument' }.freeze

  def self.fetch(entity)
    DOCUMENTS.fetch(entity == 'contact_conversations' ? 'conversations' : entity).constantize
  end

  def self.job(entity)
    entity == 'contact_conversations' ? SearchIndexing::ContactRefreshJob : SearchIndexing::FlushJob
  end
end
