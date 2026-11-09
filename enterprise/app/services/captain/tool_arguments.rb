# The arguments a Captain tool runs with. Parameters with a source take the value Chatwoot reads, and those values are
# set last, so a value from the model can never replace them. The tool is any record that answers
# requires_verified_customer?, input_schema and param_sources, entries as Captain::ParamSources describes.
#
# A run where a customer is the user calls fill. A run where an admin or an agent is the user, such as Copilot,
# lets the model fill proven values, so it calls fill_unproven and checks them with verified?.
class Captain::ToolArguments
  def initialize(tool, conversation)
    @tool = tool
    @conversation = conversation
  end

  # Every sourced value. Raises Captain::ParamSources::Unavailable when a value cannot be read.
  def fill(params)
    Captain::ParamSources.verified_email(@conversation) if @tool.requires_verified_customer?
    params.merge(values(entries))
  end

  # Only the values the customer does not prove, such as a fixed value
  def fill_unproven(params)
    params.merge(values(entries.reject { |_name, entry| Captain::ParamSources.proven?(entry) }))
  end

  # Whether the model passed the values the customer proved
  def verified?(params)
    proven = values(entries.select { |_name, entry| Captain::ParamSources.proven?(entry) })
    proven.all? { |name, value| params[name].to_s.strip.casecmp?(value) }
  rescue Captain::ParamSources::Unavailable
    false
  end

  private

  def entries
    @tool.param_sources
  end

  def values(entries)
    entries.to_h { |name, entry| [name.to_sym, Captain::ParamSources.resolve(entry, @conversation, type: property_type(name))] }
  end

  def property_type(name)
    @tool.input_schema.to_h.dig('properties', name, 'type')
  end
end
