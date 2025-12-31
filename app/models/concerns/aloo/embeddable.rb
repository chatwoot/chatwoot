# frozen_string_literal: true

module Aloo
  module Embeddable
    extend ActiveSupport::Concern

    included do
      # Use neighbor gem for vector similarity search
      has_neighbors :embedding

      scope :with_embedding, -> { where.not(embedding: nil) }
      scope :without_embedding, -> { where(embedding: nil) }

      # Semantic search using cosine similarity
      scope :semantic_search, ->(query_embedding, limit: 10) {
        with_embedding
          .nearest_neighbors(:embedding, query_embedding, distance: 'cosine')
          .limit(limit)
      }
    end

    # Override in model to specify what content to embed
    def embedding_content
      raise NotImplementedError, 'Subclass must implement #embedding_content'
    end

    # Check if embedding exists
    def embedded?
      embedding.present?
    end

    # Generate and store embedding
    def generate_embedding!
      content = embedding_content
      return if content.blank?

      response = RubyLLM.embed(content, model: 'text-embedding-3-small')
      update!(embedding: response.vectors.first)
    end

    # Calculate similarity to another embedding
    def similarity_to(other_embedding)
      return 0.0 unless embedding.present? && other_embedding.present?

      # Cosine similarity = 1 - cosine distance
      1.0 - neighbor_distance_to(other_embedding)
    end

    private

    def neighbor_distance_to(other_embedding)
      # Use pgvector's cosine distance operator
      self.class
          .where(id: id)
          .nearest_neighbors(:embedding, other_embedding, distance: 'cosine')
          .first
          &.neighbor_distance || 1.0
    end
  end
end
