# frozen_string_literal: true

require_relative "research_agent"
require_relative "analysis_agent"
require_relative "integrations_agent"
require_relative "answer_suggestion_agent"

module Copilot
  class CopilotOrchestrator
    def self.create
      # Create specialized agents
      research_agent = ResearchAgent.create
      analysis_agent = AnalysisAgent.create
      integrations_agent = IntegrationsAgent.create
      answer_suggestion_agent = AnswerSuggestionAgent.create

      # Create main orchestrator with sub-agents as tools
      Agents::Agent.new(
        name: "Support Copilot",
        instructions: orchestrator_instructions,
        model: "gpt-4o-mini",
        tools: [
          research_agent.as_tool(
            name: "research_customer_history",
            description: "Research customer history, similar cases, and behavioral patterns. Returns contact details including email addresses."
          ),
          analysis_agent.as_tool(
            name: "analyze_conversation",
            description: "Analyze conversation tone, sentiment, and communication quality"
          ),
          integrations_agent.as_tool(
            name: "check_technical_systems",
            description: "Check Linear issues and Stripe billing info. For billing checks, requires customer email address (not contact IDs)."
          ),
          answer_suggestion_agent.as_tool(
            name: "get_knowledge_base_help",
            description: "Search knowledge base and get specific article content"
          )
        ]
      )
    end

    def self.orchestrator_instructions
      <<~INSTRUCTIONS
        You are the Support Copilot, helping support agents provide excellent customer service.

        **Your specialist agents:**
        - `research_customer_history`: Deep investigation of customer history and similar cases
        - `analyze_conversation`: Conversation analysis and communication guidance
        - `check_technical_systems`: Technical context from Linear and billing from Stripe
        - `get_knowledge_base_help`: Knowledge base search and documentation retrieval

        **CRITICAL: Multi-Step Workflow Approach**

        For complex queries, you MUST break them down into logical steps and use multiple tools in sequence:

        1. **Plan your approach**: What information do you need to gather?
        2. **Execute steps sequentially**: Use EXACT results from previous tools in subsequent calls
        3. **Build context progressively**: Each tool call should build on previous findings#{"  "}
        4. **Resolve contradictions**: If tools return conflicting info, investigate further
        5. **Synthesize comprehensive response**: Combine all findings into actionable guidance

        **CRITICAL: When using tool results in subsequent calls:**
        - Extract specific values (emails, IDs, names) from previous tool outputs
        - Use those EXACT values in your next tool call
        - Don't just pass the original query parameters forward

        **DON'T:**
        - Make single tool calls for complex queries that need multiple pieces of information
        - Pass original parameters instead of discovered values to subsequent tools
        - Ignore contradictory results from different tools

        **DO:**
        - Use multiple tools sequentially with progressive information building
        - Extract and use specific values from previous tool results in next calls
        - Investigate discrepancies between different data sources
        - Plan your information gathering strategy before executing

        Always think: "What specific information did I just learn, and how do I use it in my next step?"

        Provide clear, actionable guidance. Be concise but thorough. Focus on helping the support agent succeed.
      INSTRUCTIONS
    end
  end
end
