module Enterprise::Conversations::AssignmentService
  def perform
    return super unless assignee_type.to_s == 'Captain::Assistant'
    return if conversation.inbox.external_bot_active?

    # Keep Captain ownership writes off until typed-assignee readers are deployed to every web and worker process.
    # Remove this guard in the follow-up rollout after all legacy AgentBot readers have been drained.
    return unless GlobalConfigService.load('ENABLE_CAPTAIN_CONVERSATION_ASSIGNMENT', false)

    assign_ai_assignee(captain_assistant)
  end

  private

  def captain_assistant
    assistant = conversation.inbox.captain_assistant
    assistant if assistant&.id == assignee_id.to_i
  end
end
