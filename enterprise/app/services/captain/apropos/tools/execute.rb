class Captain::Apropos::Tools::Execute < Agents::Tool
  description 'Execute a small Scheme program in the persistent session. Earlier writes survive later errors.'
  param :source, type: 'string', desc: 'Scheme source; inspect contracts before calling operations'

  def name = 'execute'

  def perform(context, source:)
    runtime = context.context.fetch(:apropos)
    result = runtime.execute(source)
    runtime.reply(result: result)
  rescue StandardError => e
    failure = {
      error: e.message, receipts_ref: runtime.store(runtime.receipts), receipt_count: runtime.receipts.size,
      progress: runtime.execution_progress,
      recovery: Captain::Apropos::Prompt.render(:execution_error)
    }
    if e.is_a?(Captain::Apropos::CallError)
      failure[:primitive] = e.primitive
      failure[:contract] = runtime.catalog.describe(e.primitive)
    end
    runtime.reply(failure)
  end
end
