class Captain::Tools::Copilot::WorkflowTool < Captain::Tools::BaseTool
  # Set by the turn before each call, so a run the tool starts is linked to that call.
  attr_accessor :tool_call
  attr_reader :run, :lease_token

  def initialize(assistant, run:, lease_token:, user: nil)
    @run = run
    @lease_token = lease_token
    super(assistant, user: user)
  end

  def active?
    user_has_permission('conversation_manage') || user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end
end
