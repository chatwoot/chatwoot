# frozen_string_literal: true

module Agents
  # AgentTool wraps an agent as a tool, enabling agent-to-agent collaboration
  # without conversation handoffs. This implementation constrains wrapped agents
  # for safety and predictability.
  #
  # Key constraints:
  # 1. Wrapped agents cannot perform handoffs (empty registry)
  # 2. Limited turn count to prevent infinite loops
  # 3. Isolated context (only shared state, no conversation history)
  # 4. Always returns to calling agent
  #
  # @example Customer support copilot with specialized agents
  #   conversation_agent = Agent.new(
  #     name: "ConversationAnalyzer",
  #     instructions: "Extract order IDs and customer intent from conversation history"
  #   )
  #
  #   actions_agent = Agent.new(
  #     name: "ShopifyActions",
  #     instructions: "Perform Shopify operations",
  #     tools: [shopify_tool]
  #   )
  #
  #   copilot = Agent.new(
  #     name: "SupportCopilot",
  #     tools: [
  #       conversation_agent.as_tool(
  #         name: "analyze_conversation",
  #         description: "Extract key info from conversation history"
  #       ),
  #       actions_agent.as_tool(
  #         name: "shopify_action",
  #         description: "Perform Shopify operations like refunds"
  #       )
  #     ]
  #   )
  class AgentTool < Tool
    attr_reader :wrapped_agent, :tool_name, :tool_description, :output_extractor

    # Default parameter for agent tools
    param :input, type: "string", desc: "Input message for the agent"

    # Initialize an AgentTool that wraps an agent as a callable tool
    #
    # @param agent [Agents::Agent] The agent to wrap as a tool
    # @param name [String, nil] Override the tool name (defaults to snake_case agent name)
    # @param description [String, nil] Override the tool description
    # @param output_extractor [Proc, nil] Custom proc to extract/transform the agent's output
    def initialize(agent:, name: nil, description: nil, output_extractor: nil)
      @wrapped_agent = agent
      @tool_name = name || transform_agent_name(agent.name)
      @tool_description = description || "Execute #{agent.name} agent"
      @output_extractor = output_extractor

      super()
    end

    def name
      @tool_name
    end

    def description
      @tool_description
    end

    # Execute the wrapped agent with constraints to prevent handoffs and recursion
    def perform(tool_context, input:)
      # Create isolated context for the wrapped agent
      isolated_context = create_isolated_context(tool_context.context)

      # Execute with explicit constraints:
      # 1. Empty registry prevents handoffs
      # 2. Low max_turns prevents infinite loops
      # 3. Isolated context prevents history access
      result = Runner.new.run(
        @wrapped_agent,
        input,
        context: isolated_context,
        registry: {}, # CONSTRAINT: No handoffs allowed
        max_turns: 3  # CONSTRAINT: Limited turns for tool execution
      )

      return "Agent execution failed: #{result.error.message}" if result.error

      # Extract output
      if @output_extractor
        @output_extractor.call(result)
      else
        result.output || "No output from #{@wrapped_agent.name}"
      end
    rescue StandardError => e
      "Error executing #{@wrapped_agent.name}: #{e.message}"
    end

    private

    def transform_agent_name(name)
      name.downcase.gsub(/\s+/, "_").gsub(/[^a-z0-9_]/, "")
    end

    # Create isolated context that only shares state, not conversation artifacts
    def create_isolated_context(parent_context)
      isolated = {}

      # Only share the state - everything else is conversation-specific
      isolated[:state] = parent_context[:state] if parent_context[:state]

      isolated
    end
  end
end
