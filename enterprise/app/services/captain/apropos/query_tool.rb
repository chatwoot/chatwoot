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
    feedback = {
      error: message,
      evidence: e.is_a?(Captain::Apropos::Error) ? e.evidence : [],
      context: e.is_a?(Captain::Apropos::Error) ? e.context : []
    }
    @runtime.record('error', feedback.except(:error).merge(message: message).deep_stringify_keys)
    feedback.to_json
  end
end
