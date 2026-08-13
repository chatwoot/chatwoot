class Captain::Tools::GetInboxAvailabilityTool < Captain::Tools::BasePublicTool
  description 'Check whether the current conversation inbox is within its configured business hours'

  def perform(tool_context)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    Captain::Routines::InboxAvailabilityService.new(
      inbox: conversation.inbox,
      evaluated_at: evaluation_time(tool_context.state)
    ).perform.to_json
  end

  private

  def evaluation_time(state)
    started_at = state&.dig(:execution, :started_at) || state&.dig('execution', 'started_at')
    started_at.present? ? Time.zone.parse(started_at.to_s) : Time.current
  end

  def safe_to_run_after_new_customer_message?
    true
  end
end
