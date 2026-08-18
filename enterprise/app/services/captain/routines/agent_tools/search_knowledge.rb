class Captain::Routines::AgentTools::SearchKnowledge < Captain::Routines::AgentTools::Base
  description 'Search accessible help-center articles and approved Captain FAQs'
  param :query, type: 'string', desc: 'Semantic knowledge search query'
  param :language, type: 'string', desc: 'Optional language code', required: false
  param :limit, type: 'integer', desc: 'Maximum results from 1 to 20', required: false

  def name = 'search_knowledge'

  def perform(tool_context, query:, language: nil, limit: 5)
    perform_operation(tool_context, 'knowledge.search', query: query, language: language, limit: limit)
  end
end
