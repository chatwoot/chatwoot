class Flows::ExitPolicyService
  def initialize(run:, event:, reason: nil, agent_user: nil)
    @run = run
    @event = event.to_s
    @reason = reason
    @agent_user = agent_user
    @conversation = run.conversation
    @policy = run.flow.resolved_exit_policy(@event).with_indifferent_access
  end

  def perform
    return unless @run.active? || @event == 'on_human_break'

    terminal_state = case @event
                     when 'on_complete' then :completed
                     when 'on_handoff', 'on_human_break' then :handed_off
                     when 'on_cancel' then :cancelled
                     else :failed
                     end

    @run.update!(
      state: terminal_state,
      ended_at: Time.current,
      ended_reason: @reason.presence || @event
    )

    FlowEvent.create!(
      flow_run: @run,
      event_type: 'exited',
      node_id: @run.current_node_id,
      data: { event: @event, reason: @reason, policy: @policy },
      created_at: Time.current
    )

    Flows::HandoffService.new(run: @run, policy: @policy).perform if ActiveModel::Type::Boolean.new.cast(@policy[:private_note]) != false &&
                                                                     %w[on_handoff on_fail on_human_break].include?(@event)

    apply_status!
    apply_assignee!
    apply_label!
    maybe_bot_handoff!
    Flows::StateSyncService.new(run: @run).perform
  end

  private

  def apply_status!
    status = @policy[:status].to_s
    case status
    when 'open' then @conversation.open!
    when 'pending' then @conversation.pending!
    when 'resolved' then @conversation.resolved!
    end
  end

  def apply_assignee!
    mode = @policy[:assignee_mode].to_s
    actions = ActionService.new(@conversation)

    case mode
    when 'keep', 'none', ''
      nil
    when 'unassigned'
      actions.remove_assigned_agent([])
      actions.remove_assigned_team([])
    when 'pending'
      # status already set; clear human assignee for bot pending queue
      actions.remove_assigned_agent([])
    when 'team'
      team_id = @policy[:team_id]
      actions.assign_team([team_id]) if team_id.present?
    when 'agent'
      agent_id = @policy[:agent_id]
      actions.assign_agent([agent_id]) if agent_id.present?
    when 'contact_owner'
      owner_id = @conversation.contact&.assigned_agent_id
      if owner_id.present?
        actions.assign_agent([owner_id])
      else
        actions.remove_assigned_agent([])
        actions.remove_assigned_team([])
      end
    end
  end

  def apply_label!
    label = @policy[:label].to_s.strip
    return if label.blank?

    ActionService.new(@conversation).add_label([label])
  end

  def maybe_bot_handoff!
    return unless @policy[:status].to_s == 'open'
    return unless %w[on_handoff on_fail].include?(@event)

    @conversation.bot_handoff!
  end
end
