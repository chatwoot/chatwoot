class Captain::Routines::Operations::Actions::ConversationAssignAgent < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.assign_agent', effect: 'internal_write',
    description: 'Assign one conversation to an account agent.',
    arguments: { conversation_id: 'conversation ID or reference', agent: 'agent name, email, ID, or reference' },
    required: %w[conversation_id agent]
  )

  def execute(conversation_id:, agent:)
    conversation = conversation!(conversation_id)
    resolved_agent = agent!(agent)
    Conversations::AssignmentService.new(conversation: conversation, assignee_id: resolved_agent.id).perform
    conversation_data(conversation.reload)
  end
end
