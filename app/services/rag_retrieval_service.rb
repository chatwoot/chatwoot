# frozen_string_literal: true

# [whisker] RAG Retrieval — finds relevant knowledge base chunks for a query
# and formats them as context for the AI model.
class RagRetrievalService
  pattr_initialize [:query!, :account!, { limit: 5, threshold: 0.3 }]

  def retrieve
    embedding = generate_query_embedding
    return [] unless embedding

    results = KnowledgeBase.search(embedding, account: account, limit: limit)
    results.select { |r| r.respond_to?(:neighbor_distance) ? r.neighbor_distance <= threshold : true }
  end

  def retrieve_as_context
    chunks = retrieve
    return '' if chunks.blank?

    context_parts = chunks.map do |chunk|
      "[#{chunk.category || 'Knowledge'}] #{chunk.name}: #{chunk.content}"
    end

    "Relevant knowledge base context:\n#{context_parts.join("\n\n")}"
  end

  private

  def generate_query_embedding
    EmbeddingService.new(query).generate
  rescue StandardError => e
    Rails.logger.error("[WhiskerRAG] Query embedding failed: #{e.message}")
    nil
  end
end
