# frozen_string_literal: true

module Agents
  # Manager for handling and emitting callback events in a thread-safe manner.
  # Provides both generic emit() method and typed convenience methods.
  #
  # @example Using generic emit
  #   manager.emit(:tool_start, tool_name, args)
  #
  # @example Using typed methods
  #   manager.emit_tool_start(tool_name, args)
  #   manager.emit_agent_thinking(agent_name, input)
  class CallbackManager
    # Supported callback event types
    EVENT_TYPES = %i[
      run_start
      run_complete
      agent_complete
      tool_start
      tool_complete
      agent_thinking
      agent_handoff
    ].freeze

    def initialize(callbacks = {})
      @callbacks = callbacks.dup.freeze
    end

    # Generic method to emit any callback event type
    #
    # @param event_type [Symbol] The type of event to emit
    # @param args [Array] Arguments to pass to callbacks
    def emit(event_type, *args)
      callback_list = @callbacks[event_type] || []

      callback_list.each do |callback|
        callback.call(*args)
      rescue StandardError => e
        # Log callback errors but don't let them crash execution
        warn "Callback error for #{event_type}: #{e.message}"
      end
    end

    # Metaprogramming: Create typed emit methods for each event type
    #
    # This generates methods like:
    #   emit_tool_start(tool_name, args)
    #   emit_tool_complete(tool_name, result)
    #   emit_agent_thinking(agent_name, input)
    #   emit_agent_handoff(from_agent, to_agent, reason)
    EVENT_TYPES.each do |event_type|
      define_method("emit_#{event_type}") do |*args|
        emit(event_type, *args)
      end
    end
  end
end
