class Captain::Tools::Copilot::ActService < Captain::Tools::Copilot::WorkflowTool
  MAX_TARGETS = 500
  ACTIONS_HELP = Captain::Copilot::Actions.all.map { |action| "- #{action::NAME}: #{action::DESCRIPTION}" }.join("\n")

  def self.name
    'act'
  end

  description 'Propose one change to every conversation in a saved collection or finished review. Nothing changes until the agent ' \
              "approves it. Returns what was applied, skipped or failed after the agent decides. Actions:\n#{ACTIONS_HELP}"
  parameters type: 'object', required: %w[source_id action arguments], additionalProperties: false,
             properties: {
               source_id: { type: 'integer', description: 'ID of a saved collection from get_data or a finished review' },
               only_matched: { type: 'boolean', description: 'For a review, change only the conversations that matched. Defaults to true' },
               action: { type: 'string', enum: Captain::Copilot::Actions.all.map { |action| action::NAME } },
               arguments: { type: 'object', description: 'Arguments for the action, as described above' }
             }

  def execute(source_id:, action:, arguments:, only_matched: true)
    Captain::Copilot::Actions.build(action, account: run.account, user: run.user, arguments: arguments)
    target_ids = target_ids(source_id, only_matched)
    raise ArgumentError, 'There are no conversations to change' if target_ids.empty?
    raise ArgumentError, "At most #{MAX_TARGETS} conversations can be changed at once. Narrow the selection." if target_ids.size > MAX_TARGETS

    action_run = run.with_lease(lease_token) { step.background_run || request_approval(source_id, action, arguments, target_ids) }
    action_run.receipt
  end

  private

  def target_ids(source_id, only_matched)
    source = run.copilot_thread.copilot_runs.where(account: run.account, user: run.user, kind: %w[collection review]).find(source_id)
    return source.selected_ids if source.kind == 'collection'
    raise ArgumentError, 'The review has not finished yet' unless source.terminal?

    findings = source.findings.where(status: 'resolved')
    findings = findings.where(matched: true) if only_matched
    findings.order(:conversation_id).pluck(:conversation_id)
  end

  # The target IDs are frozen here, so the agent approves exactly the conversations shown on the approval card.
  def request_approval(source_id, action, arguments, target_ids)
    action_run = run.copilot_thread.copilot_runs.create!(
      account: run.account, user: run.user, copilot_run_step: step, parent_run_id: source_id, kind: 'action', status: 'awaiting_approval',
      context: { action: action, arguments: arguments, target_ids: target_ids, approval_expires_at: CopilotRun::APPROVAL_TTL.from_now.iso8601 }
    )
    message = run.copilot_thread.copilot_messages.create!(
      message_type: :assistant_approval,
      message: { run_id: action_run.id, approval: { status: 'pending', action: action, arguments: arguments, count: target_ids.size } }
    )
    action_run.update!(context: action_run.context.merge('approval_message_id' => message.id))
    Captain::Copilot::ApprovalExpiryJob.set(wait: CopilotRun::APPROVAL_TTL).perform_later(action_run.id)
    action_run
  end
end
