class Flows::ExecutionService
  def initialize(run:)
    @run = run
  end

  def perform
    @run.reload
    return unless @run.active?

    node = @run.current_node
    return fail_run!('missing_node') if node.blank?

    case node['type']
    when 'actions'
      execute_actions_node(node)
    when 'send_message'
      # Legacy graphs (pre actions-node). Prefer type: actions going forward.
      execute_send_message(node)
    when 'wait_response'
      @run.update!(state: :waiting)
      Flows::StateSyncService.new(run: @run).perform
    when 'set_variable'
      execute_set_variable(node)
      advance_unconditional!(node['id'])
    when 'handoff'
      @run.append_to_trail!(node['id'], 'handoff')
      Flows::ExitPolicyService.new(run: @run, event: 'on_handoff', reason: node.dig('data', 'reason') || 'handoff_node').perform
    when 'end'
      @run.append_to_trail!(node['id'], 'end')
      Flows::ExitPolicyService.new(run: @run, event: 'on_complete', reason: 'reached_end').perform
    else
      fail_run!("unknown_node_type:#{node['type']}")
    end
  end

  def advance_after_send!(node_id)
    @run.reload
    return unless @run.active?

    @run.append_to_trail!(node_id, 'sent')
    advance_unconditional!(node_id)
  end

  def advance_to!(node_id)
    @run.update!(current_node_id: node_id, state: :running)
    Flows::StateSyncService.new(run: @run).perform
    perform
  end

  private

  def execute_actions_node(node)
    data = (node['data'] || {}).with_indifferent_access
    actions = Array(data[:actions])
    buttons = normalize_buttons(data[:buttons])
    action_svc = Flows::ActionService.new(conversation: @run.conversation, flow_run: @run)

    outbound = nil
    actions.each do |raw|
      action = raw.with_indifferent_access
      name = action[:action_name].to_s
      if name == 'send_message'
        outbound = action
      else
        begin
          action_svc.execute(action)
        rescue StandardError => e
          ChatwootExceptionTracker.new(e, account: @run.account).capture_exception
        end
      end
    end

    if outbound
      execute_outbound_send(node, outbound, buttons)
      return
    end

    @run.append_to_trail!(node['id'], 'actions')
    advance_unconditional!(node['id'])
  end

  def execute_outbound_send(node, action, buttons)
    content = Array(action[:action_params]).first.to_s
    delivery = (action[:delivery] || {}).with_indifferent_access
    delay = delivery[:delay_seconds].presence || default_delay_for(content)
    # Step-level buttons win; action may also carry buttons (editor convenience).
    btns = buttons.presence || normalize_buttons(action[:buttons])

    Flows::HumanLikeSendService.new(conversation: @run.conversation, flow_run: @run).perform(
      content: content,
      node_id: node['id'],
      buttons: btns,
      delay_seconds: delay
    )
  end

  def execute_send_message(node)
    data = (node['data'] || {}).with_indifferent_access
    delay = data[:delay_seconds].presence || default_delay_for(data[:content].to_s)
    buttons = normalize_buttons(data[:buttons])

    Flows::HumanLikeSendService.new(conversation: @run.conversation, flow_run: @run).perform(
      content: data[:content].to_s,
      node_id: node['id'],
      buttons: buttons,
      delay_seconds: delay
    )
  end

  def execute_set_variable(node)
    data = (node['data'] || {}).with_indifferent_access
    key = data[:key].to_s
    return if key.blank?

    vars = (@run.variables || {}).merge(key => data[:value])
    @run.update!(variables: vars)
    @run.append_to_trail!(node['id'], { 'set' => key })
  end

  def normalize_buttons(raw)
    Array(raw).filter_map do |b|
      b = b.is_a?(Hash) ? b.with_indifferent_access : { title: b.to_s, value: b.to_s }
      title = b[:title].to_s
      next if title.blank?

      { title: title, value: (b[:value].presence || title).to_s }
    end
  end

  def advance_unconditional!(from_node_id)
    edges = @run.flow.edges_from(from_node_id).select { |e| e['when'].blank? }
    edge = edges.first
    return fail_run!('no_next_edge') if edge.blank?

    advance_to!(edge['to'])
  end

  def default_delay_for(content)
    [[(content.length / 40.0).ceil, 2].max, 8].min
  end

  def fail_run!(reason)
    Flows::ExitPolicyService.new(run: @run, event: 'on_fail', reason: reason).perform
  end
end
