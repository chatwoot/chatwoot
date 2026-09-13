class Captain::Apropos::Tools::QueryData < Agents::Tool
  description 'Ask a read-only WootQL specialist to retrieve data. Returns query, result reference, preview, count, and pagination metadata.'
  param :request, type: 'string', desc: 'Self-contained English retrieval request. Specify scope and needed data, not actions or interpretation.'

  def name = 'query_data'

  def perform(context, request:)
    runtime = context.context.fetch(:apropos)
    runtime.reply(runtime.query_data(request))
  rescue StandardError => e
    runtime.reply(error: e.message)
  end
end
