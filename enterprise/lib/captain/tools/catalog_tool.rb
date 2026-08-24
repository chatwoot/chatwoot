class Captain::Tools::CatalogTool < Captain::Tools::BasePublicTool
  def initialize(assistant, custom_tool)
    @custom_tool = custom_tool
    super(assistant)
  end

  def active?
    @custom_tool.model_visible?
  end

  def perform(tool_context, **params)
    result = Captain::ToolCatalog::Executor.new(
      custom_tool: @custom_tool,
      state: tool_context.state
    ).perform(params)
    JSON.generate(result)
  rescue Captain::ToolCatalog::ExecutionError => e
    JSON.generate(e.model_response)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    JSON.generate(error: { category: 'upstream', code: 'tool_execution_failed' })
  end

  def available_in_reply_suggestion?
    @custom_tool.risk_read?
  end

  private

  def safe_to_run_after_new_customer_message?
    @custom_tool.risk_read?
  end
end
