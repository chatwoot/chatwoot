# frozen_string_literal: true

# Performs RAG retrieval against the agent's knowledge bases.
# Injects retrieved context into the messages as a system-level injection.
class Agent::Nodes::KnowledgeRetrievalNode < Agent::Nodes::BaseNode
  protected

  def process
    query = context.get_variable('user_message')
    top_k = data['top_k'] || 5
    kb_ids = data['knowledge_base_ids']

    rag_service = Rag::SearchService.new(account: context.ai_agent.account)
    results = rag_service.search(
      query: query,
      knowledge_base_ids: kb_ids,
      limit: top_k
    )

    # Build context string from results
    rag_context = results.pluck(:content).join("\n\n---\n\n")

    if rag_context.present?
      context.add_message(
        role: 'system',
        content: "Relevant knowledge:\n\n#{rag_context}"
      )
      context.set_variable('rag_context', rag_context)
      context.set_variable('rag_results_count', results.size)
    end

    { output: { results_count: results.size, context_length: rag_context.length } }
  end
end
