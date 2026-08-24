# frozen_string_literal: true

# [whisker] RAG Knowledge Base — stores and retrieves context chunks
# Uses pgvector for similarity search. Embeddings generated via BYOR providers.
class KnowledgeBase < ApplicationRecord
  belongs_to :account

  scope :enabled, -> { where(enabled: true) }

  validates :name, presence: true
  validates :content, presence: true

  before_save :generate_embedding, if: -> { content_changed? }

  # Similarity search — returns top N most relevant chunks
  def self.search(query_embedding, account:, limit: 5)
    where(account: account, enabled: true)
      .nearest_neighbors(:embedding, query_embedding, distance: 'cosine')
      .limit(limit)
  end

  private

  def generate_embedding
    self.embedding = EmbeddingService.new(content).generate
  end
end
