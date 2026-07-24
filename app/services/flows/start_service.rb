class Flows::StartService
  def initialize(account:, conversation:, flow:, trigger: 'automation_rule')
    @account = account
    @conversation = conversation
    @flow = flow
    @trigger = trigger
  end

  def perform
    return failure('already_in_flow') if @conversation.in_flow?
    return failure('flow_inactive') unless @flow.active?
    return failure('missing_entry') if @flow.entry_node.blank?

    run = FlowRun.create!(
      flow: @flow,
      conversation: @conversation,
      account: @account,
      state: :running,
      current_node_id: @flow.graph['entry_node_id'],
      variables: {},
      trail: [],
      trigger: @trigger,
      started_at: Time.current
    )

    FlowEvent.create!(flow_run: run, event_type: 'started', node_id: run.current_node_id, data: { trigger: @trigger }, created_at: Time.current)
    Flows::StateSyncService.new(run: run).perform
    Flows::ExecutionService.new(run: run).perform
    { success: true, flow_run: run }
  end

  private

  def failure(reason)
    { success: false, error: reason }
  end
end
