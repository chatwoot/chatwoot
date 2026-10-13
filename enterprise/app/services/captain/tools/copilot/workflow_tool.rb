class Captain::Tools::Copilot::WorkflowTool < Captain::Tools::BaseTool
  attr_accessor :run, :tool_call, :lease_token

  def active?
    user_has_permission('conversation_manage') || user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end
end
