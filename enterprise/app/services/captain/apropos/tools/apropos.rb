class Captain::Apropos::Tools::Apropos < Agents::Tool
  description 'Search the live catalog of Chatwoot entities, relationships, Scheme functions, and operations'
  param :query, type: 'string', desc: 'Words describing what you need; empty string lists the catalog'

  def name = 'apropos'

  def perform(context, query:)
    runtime = context.context.fetch(:apropos)
    result = runtime.catalog.apropos(query)
    runtime.record('discovery', { 'query' => query, 'matches' => result })
    result.to_json
  end
end
