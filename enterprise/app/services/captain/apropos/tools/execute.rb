class Captain::Apropos::Tools::Execute < Agents::Tool
  description 'Execute a small Scheme program in the persistent session. Earlier writes survive later errors.'
  param :source, type: 'string', desc: 'Scheme source; inspect contracts before calling operations'

  def name = 'execute'

  def perform(context, source:)
    runtime = context.context.fetch(:apropos)
    result = runtime.execute(source)
    runtime.reply(result: result)
  rescue StandardError
    runtime.reply(runtime.execution_failure)
  end
end
