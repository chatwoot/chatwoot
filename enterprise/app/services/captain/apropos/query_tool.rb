class Captain::Apropos::QueryTool < RubyLLM::Tool
  description 'Submit one read-only WootQL query. Validation errors allow repair; success ends this specialist call.'
  param :source, type: 'string', desc: 'WootQL source text, not Scheme or SQL. Use literal values; this tool does not accept parameters.'

  attr_reader :result

  def initialize(runtime)
    super()
    @runtime = runtime
  end

  def name = 'submit_query'

  def execute(source:)
    @result ||= @runtime.query_page(source)
    # Return control without sending database rows through another model turn.
    # https://rubyllm.com/tools/#halting-execution
    halt('Query executed. The engine has stored the results for the primary agent.')
  rescue Captain::Apropos::Error, ActiveRecord::StatementInvalid => e
    message = e.message.truncate(1_000)
    @runtime.record('error', { 'message' => message })
    {
      error: message,
      recovery: Captain::Apropos::Prompt.render(:query_error)
    }.to_json
  end
end
