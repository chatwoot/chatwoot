# frozen_string_literal: true

module Agents
  # The execution engine that orchestrates conversations between users and agents.
  # Runner manages the conversation flow, handles tool execution through RubyLLM,
  # coordinates handoffs between agents, and ensures thread-safe operation.
  #
  # The Runner follows a turn-based execution model where each turn consists of:
  # 1. Sending a message to the LLM with current context
  # 2. Receiving a response that may include tool calls
  # 3. Executing tools and getting results (handled by RubyLLM)
  # 4. Checking for agent handoffs
  # 5. Continuing until no more tools are called
  #
  # ## Thread Safety
  # The Runner ensures thread safety by:
  # - Creating new context wrappers for each execution
  # - Using tool wrappers that pass context through parameters
  # - Never storing execution state in shared variables
  #
  # ## Integration with RubyLLM
  # We leverage RubyLLM for LLM communication and tool execution while
  # maintaining our own context management and handoff logic.
  #
  # @example Simple conversation
  #   agent = Agents::Agent.new(
  #     name: "Assistant",
  #     instructions: "You are a helpful assistant",
  #     tools: [weather_tool]
  #   )
  #
  #   result = Agents::Runner.run(agent, "What's the weather?")
  #   puts result.output
  #   # => "Let me check the weather for you..."
  #
  # @example Conversation with context
  #   result = Agents::Runner.run(
  #     support_agent,
  #     "I need help with my order",
  #     context: { user_id: 123, order_id: 456 }
  #   )
  #
  # @example Multi-agent handoff
  #   triage = Agents::Agent.new(
  #     name: "Triage",
  #     instructions: "Route users to the right specialist",
  #     handoff_agents: [billing_agent, tech_agent]
  #   )
  #
  #   result = Agents::Runner.run(triage, "I can't pay my bill")
  #   # Triage agent will handoff to billing_agent
  class Runner
    DEFAULT_MAX_TURNS = 10

    class MaxTurnsExceeded < StandardError; end
    class AgentNotFoundError < StandardError; end

    # Create a thread-safe agent runner for multi-agent conversations.
    # The first agent becomes the default entry point for new conversations.
    # All agents must be explicitly provided - no automatic discovery.
    #
    # @param agents [Array<Agents::Agent>] All agents that should be available for handoffs
    # @return [AgentRunner] Thread-safe runner that can be reused across multiple conversations
    #
    # @example
    #   runner = Agents::Runner.with_agents(triage_agent, billing_agent, support_agent)
    #   result = runner.run("I need help")  # Uses triage_agent for new conversation
    #   result = runner.run("More help", context: stored_context)  # Continues with appropriate agent
    def self.with_agents(*agents)
      AgentRunner.new(agents)
    end

    # Execute an agent with the given input and context.
    # This is now called internally by AgentRunner and should not be used directly.
    #
    # @param starting_agent [Agents::Agent] The agent to run
    # @param input [String] The user's input message
    # @param context [Hash] Shared context data accessible to all tools
    # @param registry [Hash] Registry of agents for handoff resolution
    # @param max_turns [Integer] Maximum conversation turns before stopping
    # @param headers [Hash, nil] Custom HTTP headers passed to the underlying LLM provider
    # @param callbacks [Hash] Optional callbacks for real-time event notifications
    # @return [RunResult] The result containing output, messages, and usage
    def run(starting_agent, input, context: {}, registry: {}, max_turns: DEFAULT_MAX_TURNS, headers: nil, callbacks: {})
      # The starting_agent is already determined by AgentRunner based on conversation history
      current_agent = starting_agent

      # Create context wrapper with deep copy for thread safety
      context_copy = deep_copy_context(context)
      context_wrapper = RunContext.new(context_copy, callbacks: callbacks)
      current_turn = 0

      # Emit run start event
      context_wrapper.callback_manager.emit_run_start(current_agent.name, input, context_wrapper)

      runtime_headers = Helpers::Headers.normalize(headers)
      agent_headers = Helpers::Headers.normalize(current_agent.headers)

      # Create chat and restore conversation history
      chat = RubyLLM::Chat.new(model: current_agent.model)
      current_headers = Helpers::Headers.merge(agent_headers, runtime_headers)
      apply_headers(chat, current_headers)
      configure_chat_for_agent(chat, current_agent, context_wrapper, replace: false)
      restore_conversation_history(chat, context_wrapper)

      loop do
        current_turn += 1
        raise MaxTurnsExceeded, "Exceeded maximum turns: #{max_turns}" if current_turn > max_turns

        # Get response from LLM (RubyLLM handles tool execution with halting based handoff detection)
        result = if current_turn == 1
                   # Emit agent thinking event for initial message
                   context_wrapper.callback_manager.emit_agent_thinking(current_agent.name, input)
                   chat.ask(input)
                 else
                   # Emit agent thinking event for continuation
                   context_wrapper.callback_manager.emit_agent_thinking(current_agent.name, "(continuing conversation)")
                   chat.complete
                 end
        response = result

        # Check for handoff via RubyLLM's halt mechanism
        if response.is_a?(RubyLLM::Tool::Halt) && context_wrapper.context[:pending_handoff]
          handoff_info = context_wrapper.context.delete(:pending_handoff)
          next_agent = handoff_info[:target_agent]

          # Validate that the target agent is in our registry
          # This prevents handoffs to agents that weren't explicitly provided
          unless registry[next_agent.name]
            save_conversation_state(chat, context_wrapper, current_agent)
            error = AgentNotFoundError.new("Handoff failed: Agent '#{next_agent.name}' not found in registry")

            result = RunResult.new(
              output: nil,
              messages: Helpers::MessageExtractor.extract_messages(chat, current_agent),
              usage: context_wrapper.usage,
              context: context_wrapper.context,
              error: error
            )

            # Emit agent complete and run complete events with error
            context_wrapper.callback_manager.emit_agent_complete(current_agent.name, result, error, context_wrapper)
            context_wrapper.callback_manager.emit_run_complete(current_agent.name, result, context_wrapper)

            return result
          end

          # Save current conversation state before switching
          save_conversation_state(chat, context_wrapper, current_agent)

          # Emit agent complete event before handoff
          context_wrapper.callback_manager.emit_agent_complete(current_agent.name, nil, nil, context_wrapper)

          # Emit agent handoff event
          context_wrapper.callback_manager.emit_agent_handoff(current_agent.name, next_agent.name, "handoff")

          # Switch to new agent - store agent name for persistence
          current_agent = next_agent
          context_wrapper.context[:current_agent] = next_agent.name

          # Reconfigure existing chat for new agent - preserves conversation history automatically
          configure_chat_for_agent(chat, current_agent, context_wrapper, replace: true)
          agent_headers = Helpers::Headers.normalize(current_agent.headers)
          current_headers = Helpers::Headers.merge(agent_headers, runtime_headers)
          apply_headers(chat, current_headers)

          # Force the new agent to respond to the conversation context
          # This ensures the user gets a response from the new agent
          input = nil
          next
        end

        # Handle non-handoff halts - return the halt content as final response
        if response.is_a?(RubyLLM::Tool::Halt)
          save_conversation_state(chat, context_wrapper, current_agent)

          result = RunResult.new(
            output: response.content,
            messages: Helpers::MessageExtractor.extract_messages(chat, current_agent),
            usage: context_wrapper.usage,
            context: context_wrapper.context
          )

          # Emit agent complete and run complete events
          context_wrapper.callback_manager.emit_agent_complete(current_agent.name, result, nil, context_wrapper)
          context_wrapper.callback_manager.emit_run_complete(current_agent.name, result, context_wrapper)

          return result
        end

        # If tools were called, continue the loop to let them execute
        next if response.tool_call?

        # If no tools were called, we have our final response

        # Save final state before returning
        save_conversation_state(chat, context_wrapper, current_agent)

        result = RunResult.new(
          output: response.content,
          messages: Helpers::MessageExtractor.extract_messages(chat, current_agent),
          usage: context_wrapper.usage,
          context: context_wrapper.context
        )

        # Emit agent complete and run complete events
        context_wrapper.callback_manager.emit_agent_complete(current_agent.name, result, nil, context_wrapper)
        context_wrapper.callback_manager.emit_run_complete(current_agent.name, result, context_wrapper)

        return result
      end
    rescue MaxTurnsExceeded => e
      # Save state even on error
      save_conversation_state(chat, context_wrapper, current_agent) if chat

      result = RunResult.new(
        output: "Conversation ended: #{e.message}",
        messages: chat ? Helpers::MessageExtractor.extract_messages(chat, current_agent) : [],
        usage: context_wrapper.usage,
        error: e,
        context: context_wrapper.context
      )

      # Emit agent complete and run complete events with error
      context_wrapper.callback_manager.emit_agent_complete(current_agent.name, result, e, context_wrapper)
      context_wrapper.callback_manager.emit_run_complete(current_agent.name, result, context_wrapper)

      result
    rescue StandardError => e
      # Save state even on error
      save_conversation_state(chat, context_wrapper, current_agent) if chat

      result = RunResult.new(
        output: nil,
        messages: chat ? Helpers::MessageExtractor.extract_messages(chat, current_agent) : [],
        usage: context_wrapper.usage,
        error: e,
        context: context_wrapper.context
      )

      # Emit agent complete and run complete events with error
      context_wrapper.callback_manager.emit_agent_complete(current_agent.name, result, e, context_wrapper)
      context_wrapper.callback_manager.emit_run_complete(current_agent.name, result, context_wrapper)

      result
    end

    private

    # Creates a deep copy of context data for thread safety.
    # Preserves conversation history array structure while avoiding agent mutation.
    #
    # @param context [Hash] The context to copy
    # @return [Hash] Thread-safe deep copy of the context
    def deep_copy_context(context)
      # Handle deep copying for thread safety
      context.dup.tap do |copied|
        copied[:conversation_history] = context[:conversation_history]&.map(&:dup) || []
        # Don't copy agents - they're immutable
        copied[:current_agent] = context[:current_agent]
        copied[:turn_count] = context[:turn_count] || 0
      end
    end

    # Restores conversation history from context into RubyLLM chat.
    # Converts stored message hashes back into RubyLLM::Message objects with proper content handling.
    #
    # @param chat [RubyLLM::Chat] The chat instance to restore history into
    # @param context_wrapper [RunContext] Context containing conversation history
    def restore_conversation_history(chat, context_wrapper)
      history = context_wrapper.context[:conversation_history] || []

      history.each do |msg|
        # Only restore user and assistant messages with content
        next unless %i[user assistant].include?(msg[:role].to_sym)
        next unless msg[:content] && !Helpers::MessageExtractor.content_empty?(msg[:content])

        # Extract text content safely - handle both string and hash content
        content = RubyLLM::Content.new(msg[:content])

        # Create a proper RubyLLM::Message and pass it to add_message
        message = RubyLLM::Message.new(
          role: msg[:role].to_sym,
          content: content
        )
        chat.add_message(message)
      end
    end

    # Saves current conversation state from RubyLLM chat back to context for persistence.
    # Maintains conversation continuity across agent handoffs and process boundaries.
    #
    # @param chat [RubyLLM::Chat] The chat instance to extract state from
    # @param context_wrapper [RunContext] Context to save state into
    # @param current_agent [Agents::Agent] The currently active agent
    def save_conversation_state(chat, context_wrapper, current_agent)
      # Extract messages from chat
      messages = Helpers::MessageExtractor.extract_messages(chat, current_agent)

      # Update context with latest state
      context_wrapper.context[:conversation_history] = messages
      context_wrapper.context[:current_agent] = current_agent.name
      context_wrapper.context[:turn_count] = (context_wrapper.context[:turn_count] || 0) + 1
      context_wrapper.context[:last_updated] = Time.now

      # Clean up temporary handoff state
      context_wrapper.context.delete(:pending_handoff)
    end

    # Configures a RubyLLM chat instance with agent-specific settings.
    # Uses RubyLLM's replace option to swap agent context while preserving conversation history during handoffs.
    #
    # @param chat [RubyLLM::Chat] The chat instance to configure
    # @param agent [Agents::Agent] The agent whose configuration to apply
    # @param context_wrapper [RunContext] Thread-safe context wrapper
    # @param replace [Boolean] Whether to replace existing configuration (true for handoffs, false for initial setup)
    # @return [RubyLLM::Chat] The configured chat instance
    def configure_chat_for_agent(chat, agent, context_wrapper, replace: false)
      # Get system prompt (may be dynamic)
      system_prompt = agent.get_system_prompt(context_wrapper)

      # Combine all tools - both handoff and regular tools need wrapping
      all_tools = build_agent_tools(agent, context_wrapper)

      # Switch model if different (important for handoffs between agents using different models)
      chat.with_model(agent.model) if replace

      # Configure chat with instructions, temperature, tools, and schema
      chat.with_instructions(system_prompt, replace: replace) if system_prompt
      chat.with_temperature(agent.temperature) if agent.temperature
      chat.with_tools(*all_tools, replace: replace)
      chat.with_schema(agent.response_schema) if agent.response_schema

      chat
    end

    def apply_headers(chat, headers)
      return if headers.empty?

      chat.with_headers(**headers)
    end

    # Builds thread-safe tool wrappers for an agent's tools and handoff tools.
    #
    # @param agent [Agents::Agent] The agent whose tools to wrap
    # @param context_wrapper [RunContext] Thread-safe context wrapper for tool execution
    # @return [Array<ToolWrapper>] Array of wrapped tools ready for RubyLLM
    def build_agent_tools(agent, context_wrapper)
      all_tools = []

      # Add handoff tools
      agent.handoff_agents.each do |target_agent|
        handoff_tool = HandoffTool.new(target_agent)
        all_tools << ToolWrapper.new(handoff_tool, context_wrapper)
      end

      # Add regular tools
      agent.tools.each do |tool|
        all_tools << ToolWrapper.new(tool, context_wrapper)
      end

      all_tools
    end
  end
end
