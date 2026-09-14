class Captain::Apropos::Tools::Describe < Agents::Tool
  description 'Read domain knowledge or inspect an entity, relationship catalog, function signature, operation, or saved binding'
  param :name, type: 'string', desc: 'Exact catalog entry name'

  def name = 'describe'

  def perform(context, name:)
    runtime = context.context.fetch(:apropos)
    result = runtime.catalog.describe(name)
    runtime.record('description', { 'name' => name, 'contract' => result })
    runtime.reply(result)
  rescue KeyError, Captain::Apropos::Error => e
    runtime.reply(error: e.message)
  end
end
