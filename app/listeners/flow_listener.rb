class FlowListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)&.first
    return if message.blank?

    conversation = message.conversation
    return if conversation.blank?
    return unless conversation.account.feature_enabled?('flows_v1')

    run = conversation.active_flow_run
    return if run.blank?

    if message.incoming?
      return unless run.waiting?

      Flows::EvaluatorService.new(run: run, message: message).perform
    elsif agent_human_break?(message)
      Flows::ExitPolicyService.new(
        run: run,
        event: 'on_human_break',
        reason: 'human_responded',
        agent_user: message.sender
      ).perform
    end
  end

  private

  def agent_human_break?(message)
    return false unless message.outgoing? && !message.private?
    return false if message.content_attributes&.dig('flow_run_id').present?
    return false if message.sender_type == 'AgentBot'
    return false if message.sender_type == 'Captain::Assistant'

    message.sender_type == 'User'
  end
end
