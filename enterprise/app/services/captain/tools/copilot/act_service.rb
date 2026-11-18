class Captain::Tools::Copilot::ActService < Captain::Tools::Copilot::WorkflowTool
  MAX_TARGETS = 500
  ACTIONS_HELP = Captain::Copilot::Actions.all.map { |action| "- #{action::NAME}: #{action::DESCRIPTION}" }.join("\n")

  def self.name
    'act'
  end

  description 'Propose one change to every record in a saved collection or finished review. Nothing changes until the agent ' \
              'approves it. Returns what was applied, already applied or failed after the agent decides. Already applied records ' \
              "had the change before and were left as they were. Actions:\n#{ACTIONS_HELP}"
  parameters type: 'object', required: %w[saved_set_id action arguments], additionalProperties: false,
             properties: {
               saved_set_id: { type: 'integer',
                               description: "ID of a saved collection or finished review holding the action's resource. Every " \
                                            'record in it is changed, so to change only some, save a narrower set with get_data first' },
               only_matched: { type: 'boolean',
                               description: 'For a review: true changes only matched conversations; false changes every conversation ' \
                                            'the review finished, including screened out ones. Defaults to true' },
               action: { type: 'string', enum: Captain::Copilot::Actions.all.map { |action| action::NAME } },
               arguments: { type: 'object', description: 'Arguments for the action, as described above' }
             }

  def execute(saved_set_id:, action:, arguments:, only_matched: true)
    proposed = Captain::Copilot::Actions.build(action, account: run.account, user: run.user, arguments: arguments)
    source = run.copilot_thread.saved_set(saved_set_id)
    target_ids = target_ids(source, proposed.class::RESOURCE, only_matched)
    raise ArgumentError, 'There are no records to change' if target_ids.empty?
    raise ArgumentError, "At most #{MAX_TARGETS} records can be changed at once. Narrow the selection." if target_ids.size > MAX_TARGETS

    action_run = run.with_lease(lease_token) { tool_call.background_run || request_approval(source, proposed, arguments, target_ids) }
    action_run.summary
  end

  private

  def target_ids(source, resource, only_matched)
    return source.record_ids(only_matched: only_matched) if source.resource == resource

    raise ArgumentError, "This action changes #{resource}, but the source holds #{source.resource}. " \
                         "Use get_data with resource #{resource} and from #{source.id} first."
  end

  # The target IDs are frozen here, so the agent approves exactly the records counted and linked on the approval card.
  def request_approval(source, proposed, arguments, target_ids)
    context = { action: proposed.class::NAME, arguments: arguments, target_ids: target_ids,
                proposal_values: proposed.proposal_values(target_ids).presence }.compact
    action_run = CopilotRun::Action.create!(
      copilot_thread: run.copilot_thread, account: run.account, user: run.user, copilot_tool_call: tool_call, source_run: source,
      status: :awaiting_approval, context: context
    )
    card = approval_card(action_run, proposed, source)
    action_run.update!(context: action_run.context.merge('approval_message_id' => card.id))
    Captain::Copilot::ApprovalExpiryJob.set(wait: CopilotRun::Action::APPROVAL_TTL).perform_later(action_run.id)
    action_run
  end

  def approval_card(action_run, proposed, source)
    ids = action_run.target_ids
    approval = { status: 'awaiting_approval', action: proposed.class::NAME, arguments: action_run.context['arguments'], count: ids.size,
                 targets: action_run.target_links(ids), coverage: review_coverage(source),
                 expires_at: (action_run.created_at + CopilotRun::Action::APPROVAL_TTL).to_i }.merge(proposed.card(ids))
    run.copilot_thread.copilot_messages.create!(message_type: :assistant_approval, message: { run_id: action_run.id, approval: approval.compact })
  end

  # A review that stopped at its turn limit, or could not review some conversations, covers only part of its selection. The
  # card says so, so the agent does not approve a partial set as if it were complete.
  def review_coverage(source)
    return unless source.is_a?(CopilotRun::Review)

    summary = source.summary
    reviewed = summary[:processed] - summary[:failed]
    { reviewed: reviewed, total: summary[:selected] } if reviewed < summary[:selected]
  end
end
