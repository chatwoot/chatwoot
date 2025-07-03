class Captain::Agents::CopilotOrchestratorAgent
  def self.create(assistant, user: nil)
    # Create the specialized agents using factory pattern
    research_agent = Captain::Agents::ResearchAgent.create(assistant, user: user)
    analysis_agent = Captain::Agents::AnalysisAgent.create(assistant, user: user)
    integrations_agent = Captain::Agents::IntegrationsAgent.create(assistant, user: user)
    knowledge_agent = Captain::Agents::KnowledgeAgent.create(assistant, user: user)

    # Create the main orchestrator agent
    ::Agents::Agent.new(
      name: 'Chatwoot Copilot',
      instructions: orchestrator_instructions,
      model: 'gpt-4.1-mini',
      tools: [
        research_agent.as_tool(
          name: 'research_agent',
          description: "Get conversation details by ID, search conversations by status/contact, find contact info, search knowledge articles. Use for: 'Get conversation 12345', 'Find recent conversations', 'Search for customer john@example.com'"
        ),
        analysis_agent.as_tool(
          name: 'analysis_agent',
          description: 'Analyze conversations for sentiment, quality, and patterns. Provide insights on customer emotions and support effectiveness. Use after getting conversation data from research_agent.'
        ),
        integrations_agent.as_tool(
          name: 'integrations_agent',
          description: "Update conversation status, change priority, add/remove labels, assign agents. Use for: 'Mark as resolved', 'Set priority to high', 'Add billing label'"
        ),
        knowledge_agent.as_tool(
          name: 'knowledge_agent',
          description: "Search help articles, find policies, get documentation. Use for: 'Find refund policy', 'Search billing articles', 'What's our shipping policy'"
        )
      ]
    )
  end

  def self.orchestrator_instructions
    lambda { |context|
      state = context.context[:state] || {}

      base_instructions = <<~INSTRUCTIONS
        You are the Chatwoot Copilot. Help agents with customer support tasks.

        Tools available:
        - research_agent: Get conversation details, find contacts, search articles
        - analysis_agent: Analyze conversations for sentiment and insights
        - integrations_agent: Update conversation status, priority, labels
        - knowledge_agent: Find help articles and policies

        How to use tools:
        - For conversation summary: research_agent("Get conversation [ID]")
        - For sentiment analysis: research_agent first, then analysis_agent
        - For status updates: integrations_agent("Mark conversation as resolved")
        - For help content: knowledge_agent("Find billing policy")

        Always get conversation data first before analysis or recommendations.
      INSTRUCTIONS

      # Add current conversation context if available
      if state[:current_conversation]
        conversation = state[:current_conversation]
        base_instructions += <<~CONTEXT

          **Current Conversation:**
          ID: #{conversation[:display_id]}
          Status: #{conversation[:status]}
          Contact: #{conversation[:contact_name]}
          Assignee: #{conversation[:assignee] || 'Unassigned'}
          Last Activity: #{conversation[:last_activity]}

          This conversation is currently #{conversation[:status]} and assigned to #{conversation[:assignee] || 'no one'}.
          The customer #{conversation[:contact_name]} was last active #{conversation[:last_activity]}.
        CONTEXT
      end

      base_instructions
    }
  end
end
