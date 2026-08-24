module Captain::ToolCatalog::TracingSanitizer
  REDACTED_PAYLOAD = { redacted: true }.freeze
  TRACE_TOOL_KEY = :captain_catalog_trace_tool

  def self.install!
    callbacks = Agents::Instrumentation::TracingCallbacks
    callbacks.prepend(self) unless callbacks.ancestors.include?(self)
  end

  def on_tool_start(tool_name, args, context_wrapper)
    context_wrapper.context.delete(TRACE_TOOL_KEY)
    return super unless catalog_tool?(tool_name, context_wrapper)

    context_wrapper.context[TRACE_TOOL_KEY] = tool_name
    super(tool_name, REDACTED_PAYLOAD, context_wrapper)
  end

  def on_tool_complete(tool_name, result, context_wrapper)
    return super unless context_wrapper.context[TRACE_TOOL_KEY] == tool_name

    super(tool_name, REDACTED_PAYLOAD, context_wrapper)
  ensure
    context_wrapper&.context&.delete(TRACE_TOOL_KEY)
  end

  private

  def catalog_tool?(tool_name, context_wrapper)
    names = context_wrapper&.context&.dig(:state, :captain_catalog_tool_names) || []
    names.include?(tool_name)
  end
end
