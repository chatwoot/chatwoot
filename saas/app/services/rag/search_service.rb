# frozen_string_literal: true

# Performs semantic search across an AI agent's knowledge bases.
# Returns top-K relevant chunks formatted as context for the LLM.
module Rag
  class SearchService
    DEFAULT_LIMIT = 5

    def initialize(account:, api_key: nil)
      @account = account
      @embedding_service = Rag::EmbeddingService.new(account: account, api_key: api_key)
    end

    # Search across all active knowledge bases for the given AI agent.
    # Returns an array of { content:, title:, score:, document_id: } hashes.
    def search(ai_agent:, query:, limit: DEFAULT_LIMIT)
      knowledge_base_ids = ai_agent.knowledge_bases.active.pluck(:id)
      return [] if knowledge_base_ids.empty?

      query_embedding = @embedding_service.embed_query(query)
      return [] if query_embedding.blank?

      Saas::KnowledgeDocument
        .where(knowledge_base_id: knowledge_base_ids)
        .ready
        .nearest_neighbors(:embedding, query_embedding, distance: :cosine)
        .first(limit)
        .map do |doc|
          {
            content: doc.content,
            title: doc.title,
            score: doc.neighbor_distance,
            document_id: doc.id
          }
        end
    end

    # Format search results as a context string to inject into a system prompt.
    def build_context(ai_agent:, query:, limit: DEFAULT_LIMIT)
      results = search(ai_agent: ai_agent, query: query, limit: limit)
      return nil if results.empty?

      context_parts = results.map.with_index(1) do |r, i|
        "[#{i}] #{r[:title]}\n#{r[:content]}"
      end

      <<~CONTEXT
        Use the following knowledge base excerpts to answer the user's question. If the answer is not in these excerpts, say so.

        ---
        #{context_parts.join("\n\n---\n")}
        ---
      CONTEXT
    end
  end
end
