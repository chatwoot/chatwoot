class Captain::Tools::Copilot::ActService < Captain::Tools::Copilot::WorkflowTool
  MAX_TARGETS = 500
  # The approval card links this many targets and counts the rest.
  PREVIEW_TARGETS = 10
  ACTIONS_HELP = Captain::Copilot::Actions.all.map { |action| "- #{action::NAME}: #{action::DESCRIPTION}" }.join("\n")

  def self.name
    'act'
  end

  description 'Propose one change to every conversation in a saved collection or finished review. Nothing changes until the agent ' \
              "approves it. Returns what was applied, skipped or failed after the agent decides. Actions:\n#{ACTIONS_HELP}"
  parameters type: 'object', required: %w[source_id action arguments], additionalProperties: false,
             properties: {
               source_id: { type: 'integer', description: "ID of a saved collection or finished review holding the action's resource" },
               only_matched: { type: 'boolean',
                               description: 'For a review: true changes only matched conversations; false changes every conversation ' \
                                            'the review finished, including screened out ones. Defaults to true' },
               action: { type: 'string', enum: Captain::Copilot::Actions.all.map { |action| action::NAME } },
               arguments: { type: 'object', description: 'Arguments for the action, as described above' }
             }

  def execute(source_id:, action:, arguments:, only_matched: true)
    proposed = Captain::Copilot::Actions.build(action, account: run.account, user: run.user, arguments: arguments)
    target_ids = target_ids(source_id, proposed.class::RESOURCE, only_matched)
    raise ArgumentError, 'There are no records to change' if target_ids.empty?
    raise ArgumentError, "At most #{MAX_TARGETS} records can be changed at once. Narrow the selection." if target_ids.size > MAX_TARGETS

    targets = { resource: proposed.class::RESOURCE, ids: target_ids }
    action_run = run.with_lease(lease_token) { step.background_run || request_approval(source_id, action, arguments, targets) }
    action_run.receipt
  end

  private

  def target_ids(source_id, resource, only_matched)
    source = saved_run(source_id, %w[collection review])
    return source.record_ids(only_matched: only_matched) if source.resource == resource

    raise ArgumentError, "This action changes #{resource}, but the source holds #{source.resource}. " \
                         "Use get_data with resource #{resource} and from #{source.id} first."
  end

  # The target IDs are frozen here, so the agent approves exactly the records counted and linked on the approval card.
  def request_approval(source_id, action, arguments, targets)
    action_run = run.copilot_thread.copilot_runs.create!(
      account: run.account, user: run.user, copilot_run_step: step, parent_run_id: source_id, kind: 'action', status: 'awaiting_approval',
      context: { action: action, arguments: arguments, target_ids: targets[:ids], approval_expires_at: CopilotRun::APPROVAL_TTL.from_now.iso8601 }
    )
    card = approval_card(action_run, targets)
    action_run.update!(context: action_run.context.merge('approval_message_id' => card.id))
    Captain::Copilot::ApprovalExpiryJob.set(wait: CopilotRun::APPROVAL_TTL).perform_later(action_run.id)
    action_run
  end

  def approval_card(action_run, targets)
    resource = Captain::Copilot::Resources.build(targets[:resource], account: run.account, user: run.user)
    links = resource.rows(targets[:ids].first(PREVIEW_TARGETS)).map { |row| row.slice(:label, :url) }
    approval = { status: 'pending', action: action_run.context['action'], arguments: action_run.context['arguments'],
                 count: targets[:ids].size, targets: links }
    run.copilot_thread.copilot_messages.create!(message_type: :assistant_approval, message: { run_id: action_run.id, approval: approval })
  end
end
