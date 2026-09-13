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
      recovery: 'Inspect the failing contract with describe, repair the smallest failing expression, and continue within the original request. ' \
                'Reuse available_bindings; completed_bindings succeeded in this call. Repair failed_binding without repeating retrieval. ' \
                'Earlier writes may have succeeded. Inspect receipts before retrying any action; never blindly replay writes. ' \
                'Keep the original targets and eligibility conditions. An empty result is not permission to act on other records.'
    }
    if e.is_a?(Captain::Apropos::CallError)
      failure[:primitive] = e.primitive
      failure[:contract] = runtime.catalog.describe(e.primitive)
    end
    runtime.reply(failure)
  end
end
