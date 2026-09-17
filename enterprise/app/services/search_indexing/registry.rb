module SearchIndexing::Registry
  # Register projections as their lifecycle writers are introduced.
  DOCUMENTS = { 'contacts' => 'SearchIndexing::ContactDocument' }.freeze

  def self.fetch(entity)
    DOCUMENTS.fetch(entity).constantize
  end
end
