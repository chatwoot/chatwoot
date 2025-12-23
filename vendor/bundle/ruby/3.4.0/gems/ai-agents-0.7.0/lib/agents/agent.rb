# frozen_string_literal: true

# The core agent definition that represents an AI assistant with specific capabilities.
# Agents are immutable, thread-safe objects that can be cloned with modifications.
# They encapsulate the configuration needed to interact with an LLM including
# instructions, tools, and potential handoff targets.
require_relative "helpers/headers"
# @example Creating a basic agent
#   agent = Agents::Agent.new(
#     name: "Assistant",
#     instructions: "You are a helpful assistant",
#     model: "gpt-4",
#     tools: [calculator_tool, weather_tool]
#   )
#
# @example Creating an agent with structured output
#   agent = Agents::Agent.new(
#     name: "DataExtractor",
#     instructions: "Extract structured information from user input",
#     model: "gpt-4o",
#     response_schema: {
#       type: 'object',
#       properties: {
#         entities: { type: 'array', items: { type: 'string' } },
#         sentiment: { type: 'string', enum: ['positive', 'negative', 'neutral'] },
#         summary: { type: 'string' }
#       },
#       required: ['entities', 'sentiment'],
#       additionalProperties: false
#     }
#   )
#
# @example Creating an agent with dynamic state-aware instructions
#   agent = Agents::Agent.new(
#     name: "Support Agent",
#     instructions: ->(context) {
#       state = context.context[:state] || {}
#       base = "You are a support agent."
#       if state[:customer_name]
#         base += " Customer: #{state[:customer_name]} (#{state[:customer_id]})"
#       end
#       base
#     }
#   )
#
# @example Cloning an agent with modifications
#   specialized_agent = base_agent.clone(
#     instructions: "You are a specialized assistant",
#     tools: base_agent.tools + [new_tool]
#   )
module Agents
  class Agent
    attr_reader :name, :instructions, :model, :tools, :handoff_agents, :temperature, :response_schema, :headers

    # Initialize a new Agent instance
    #
    # @param name [String] The name of the agent
    # @param instructions [String, Proc, nil] Static string or dynamic Proc that returns instructions
    # @param model [String] The LLM model to use (default: "gpt-4.1-mini")
    # @param tools [Array<Agents::Tool>] Array of tool instances the agent can use
    # @param handoff_agents [Array<Agents::Agent>] Array of agents this agent can hand off to
    # @param temperature [Float] Controls randomness in responses (0.0 = deterministic, 1.0 = very random, default: 0.7)
    # @param response_schema [Hash, nil] JSON schema for structured output responses
    # @param headers [Hash, nil] Default HTTP headers applied to LLM requests
    def initialize(name:, instructions: nil, model: "gpt-4.1-mini", tools: [], handoff_agents: [], temperature: 0.7,
                   response_schema: nil, headers: nil)
      @name = name
      @instructions = instructions
      @model = model
      @tools = tools.dup
      @handoff_agents = []
      @temperature = temperature
      @response_schema = response_schema
      @headers = Helpers::Headers.normalize(headers, freeze_result: true)

      # Mutex for thread-safe handoff registration
      # While agents are typically configured at startup, we want to ensure
      # that concurrent handoff registrations don't result in lost data.
      # For example, in a web server with multiple threads initializing
      # different parts of the system, we might have:
      #   Thread 1: triage.register_handoffs(billing)
      #   Thread 2: triage.register_handoffs(support)
      # Without synchronization, one registration could overwrite the other.
      @mutex = Mutex.new

      # Register initial handoff agents if provided
      register_handoffs(*handoff_agents) unless handoff_agents.empty?
    end

    # Get all tools available to this agent, including any auto-generated handoff tools
    #
    # @return [Array<Agents::Tool>] All tools available to the agent
    def all_tools
      @mutex.synchronize do
        # Compute handoff tools dynamically
        handoff_tools = @handoff_agents.map { |agent| HandoffTool.new(agent) }
        @tools + handoff_tools
      end
    end

    # Register agents that this agent can hand off to.
    # This method can be called after agent creation to set up handoff relationships.
    # Thread-safe: Multiple threads can safely call this method concurrently.
    #
    # @param agents [Array<Agents::Agent>] Agents to register as handoff targets
    # @return [self] Returns self for method chaining
    # @example Setting up hub-and-spoke pattern
    #   # Create agents
    #   triage = Agent.new(name: "Triage", instructions: "Route to specialists")
    #   billing = Agent.new(name: "Billing", instructions: "Handle payments")
    #   support = Agent.new(name: "Support", instructions: "Fix technical issues")
    #
    #   # Wire up handoffs after creation - much cleaner than complex factories!
    #   triage.register_handoffs(billing, support)
    #   billing.register_handoffs(triage)  # Specialists only handoff back to triage
    #   support.register_handoffs(triage)
    def register_handoffs(*agents)
      @mutex.synchronize do
        @handoff_agents.concat(agents)
        @handoff_agents.uniq! # Prevent duplicates
      end
      self
    end

    # Creates a new agent instance with modified attributes while preserving immutability.
    # The clone method is used when you need to create variations of agents without mutating the original.
    # This can be used for runtime agent modifications, say in a multi-tenant environment we can do something like the following:
    #
    # @example Multi-tenant agent customization
    #   def agent_for_tenant(tenant)
    #     @base_agent.clone(
    #       instructions: "You work for #{tenant.company_name}",
    #       tools: @base_agent.tools + tenant.custom_tools
    #     )
    #   end
    #
    # @example Creating specialized variants
    #   finance_writer = @writer_agent.clone(
    #     tools: @writer_agent.tools + [financial_research_tool]
    #   )
    #
    #   marketing_writer = @writer_agent.clone(
    #     tools: @writer_agent.tools + [marketing_research_tool]
    #   )
    #
    # The key insight to note here is that clone ensures immutability - you never accidentally modify a shared agent
    # instance that other requests might be using. This is critical for thread safety in concurrent
    # environments.
    #
    # This also ensures we also get to leverage the syntax sugar defining a class provides us with.
    #
    # @param changes [Hash] Keyword arguments for attributes to change
    # @option changes [String] :name New agent name
    # @option changes [String, Proc] :instructions New instructions
    # @option changes [String] :model New model identifier
    # @option changes [Array<Agents::Tool>] :tools New tools array (replaces all tools)
    # @option changes [Array<Agents::Agent>] :handoff_agents New handoff agents
    # @option changes [Float] :temperature Temperature for LLM responses (0.0-1.0)
    # @option changes [Hash, nil] :response_schema JSON schema for structured output
    # @return [Agents::Agent] A new frozen agent instance with the specified changes
    def clone(**changes)
      self.class.new(
        name: changes.fetch(:name, @name),
        instructions: changes.fetch(:instructions, @instructions),
        model: changes.fetch(:model, @model),
        tools: changes.fetch(:tools, @tools.dup),
        handoff_agents: changes.fetch(:handoff_agents, @handoff_agents),
        temperature: changes.fetch(:temperature, @temperature),
        response_schema: changes.fetch(:response_schema, @response_schema),
        headers: changes.fetch(:headers, @headers)
      )
    end

    # Get the system prompt for the agent, potentially customized based on runtime context.
    # We will allow setting up a Proc for instructions.
    # This will allow us the inject context in runtime.
    #
    # @example Static instructions (most common)
    #   agent = Agent.new(
    #     name: "Support",
    #     instructions: "You are a helpful support agent"
    #   )
    #
    # @example Dynamic instructions with state awareness
    #   agent = Agent.new(
    #     name: "Sales Agent",
    #     instructions: ->(context) {
    #       state = context.context[:state] || {}
    #       base = "You are a sales agent."
    #       if state[:customer_name] && state[:current_plan]
    #         base += " Customer: #{state[:customer_name]} on #{state[:current_plan]} plan."
    #       end
    #       base
    #     }
    #   )
    #
    # @param context [Agents::RunContext] The current execution context containing runtime data
    # @return [String, nil] The system prompt string or nil if no instructions are set
    def get_system_prompt(context)
      # TODO: Add string interpolation support for instructions
      # Allow instructions like "You are helping %{customer_name}" that automatically
      # get state values injected from context[:state] using Ruby's % formatting
      case instructions
      when String
        instructions
      when Proc
        instructions.call(context)
      end
    end

    # Transform this agent into a tool, callable by other agents.
    # This enables agent-to-agent collaboration without conversation handoffs.
    #
    # Agent-as-tool is different from handoffs in two key ways:
    # 1. The wrapped agent receives generated input, not conversation history
    # 2. The wrapped agent returns a result to the calling agent, rather than taking over
    #
    # @param name [String, nil] Override the tool name (defaults to snake_case agent name)
    # @param description [String, nil] Override the tool description
    # @param output_extractor [Proc, nil] Custom proc to extract/transform the agent's output
    # @param params [Hash] Additional parameter definitions for the tool
    # @return [Agents::AgentTool] A tool that wraps this agent
    #
    # @example Basic agent-as-tool
    #   research_agent = Agent.new(name: "Researcher", instructions: "Research topics")
    #   research_tool = research_agent.as_tool(
    #     name: "research_topic",
    #     description: "Research a topic using company knowledge base"
    #   )
    #
    # @example Custom output extraction
    #   analyzer_tool = analyzer_agent.as_tool(
    #     output_extractor: ->(result) { result.context[:extracted_data]&.to_json || result.output }
    #   )
    #
    def as_tool(name: nil, description: nil, output_extractor: nil)
      AgentTool.new(
        agent: self,
        name: name,
        description: description,
        output_extractor: output_extractor
      )
    end
  end
end
