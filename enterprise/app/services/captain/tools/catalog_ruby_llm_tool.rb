class Captain::Tools::CatalogRubyLlmTool < Captain::Tools::BaseTool
  def initialize(assistant, custom_tool, conversation: nil)
    @custom_tool = custom_tool
    @conversation = conversation
    super(assistant)
  end

  def active?
    @custom_tool.model_visible?
  end

  def execute(**params)
    result = Captain::ToolCatalog::Executor.new(
      custom_tool: @custom_tool,
      state: execution_state
    ).perform(params)
    JSON.generate(result)
  rescue Captain::ToolCatalog::ExecutionError => e
    JSON.generate(e.model_response)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    JSON.generate(error: { category: 'upstream', code: 'tool_execution_failed' })
  end

  private

  def execution_state
    state = { account_id: assistant.account_id, assistant_id: assistant.id }
    return state if @conversation.blank?

    state.merge(
      conversation: record_attributes(@conversation, :id, :display_id),
      contact: record_attributes(@conversation.contact, :id, :email, :phone_number),
      contact_inbox: record_attributes(@conversation.contact_inbox, :id, :hmac_verified)
    )
  end

  def record_attributes(record, *keys)
    record&.attributes&.symbolize_keys&.slice(*keys)
  end
end
