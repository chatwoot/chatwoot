class Captain::Apropos::Tools::Describe < Agents::Tool
  description 'Inspect an entity, relationship catalog, function signature, operation, or saved binding'
  param :name, type: 'string', desc: 'Exact catalog entry name'

  def name = 'describe'

  def perform(context, name:)
    runtime = context.context.fetch(:apropos)
    result = runtime.catalog.describe(name)
    runtime.record('description', { 'name' => name, 'contract' => result })
    result.to_json
  rescue KeyError, Captain::Apropos::Error => e
    { error: e.message }.to_json
  end
end
