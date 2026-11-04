# The arguments a Captain tool runs with. Parameters with a source take the value Chatwoot reads from what
# the customer proved. Those values are set last, so a value from the model can never replace them.
# The tool is any record that answers requires_email_verification? and param_sources, such as a custom tool.
class Captain::ToolArguments
  def initialize(tool, conversation)
    @tool = tool
    @conversation = conversation
  end

  # Raises Captain::ParamSources::Unavailable when a value cannot be read
  def fill(params)
    require_verified_email! if @tool.requires_email_verification?
    params.merge(sourced_values)
  end

  # Whether the model passed the values the customer proved, for runs where the model fills them
  def verified?(params)
    sourced_values.all? { |name, value| params[name].to_s.strip.casecmp?(value) }
  rescue Captain::ParamSources::Unavailable
    false
  end

  private

  # The tool asks for a verified email even when no parameter takes it, so only the check matters
  def require_verified_email!
    Captain::ParamSources::VerifiedEmail.new.resolve(@conversation)
  end

  def sourced_values
    @sourced_values ||= @tool.param_sources.to_h { |name, source| [name.to_sym, source.resolve(@conversation)] }
  end
end
