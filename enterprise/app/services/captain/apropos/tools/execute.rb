class Captain::Apropos::Tools::Execute < Agents::Tool
  description 'Execute a small Scheme program in the persistent session. Earlier writes survive later errors.'
  param :source, type: 'string', desc: 'Scheme source; inspect contracts before calling operations'

  def name = 'execute'

  def perform(context, source:)
    runtime = context.context.fetch(:apropos)
    result = runtime.execute(source)
    { result: result }.to_json
  rescue StandardError => e
    failure = {
      error: e.message, receipts: runtime.receipts,
      recovery: 'Inspect the failing contract with describe, repair the smallest failing expression, and continue within the original request. ' \
                'Earlier bindings and writes may have succeeded. Inspect receipts before retrying any action; never blindly replay writes.'
    }
    if e.is_a?(Captain::Apropos::CallError)
      failure[:primitive] = e.primitive
      failure[:contract] = runtime.catalog.describe(e.primitive)
    end
    failure.to_json
  end
end
