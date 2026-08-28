class Captain::Tools::Admin::Executor
  def self.tools_by_key
    @tools_by_key ||= Captain::Tools::Admin::Registry::WRITE_TOOLS.index_by(&:name)
  end

  def self.execute!(pending_action:, assistant:, user:)
    tool_class = tools_by_key[pending_action.tool_name]
    raise ArgumentError, "Unknown admin tool: #{pending_action.tool_name}" if tool_class.blank?

    params = pending_action.action_params.symbolize_keys
    tool = tool_class.new(assistant, user: user)
    tool.execute(confirmed: true, **params)
  end
end
