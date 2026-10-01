class Captain::Tools::Copilot::WorkflowTool < Captain::Tools::BaseTool
  attr_accessor :run, :step, :lease_token

  def active?
    user_has_permission('conversation_manage') || user_has_permission('conversation_unassigned_manage') ||
      user_has_permission('conversation_participating_manage')
  end

  private

  def saved_run(id, kind)
    run.copilot_thread.copilot_runs.where(account: run.account, user: run.user, kind: kind).find(id)
  end
end
