# frozen_string_literal: true

# Tool is the base class for all agent tools, providing a thread-safe interface for
# agents to interact with external systems and perform actions. Tools extend RubyLLM::Tool
# while adding critical thread-safety guarantees and enhanced error handling.
#
# ## Thread-Safe Design Principles
# Tools extend RubyLLM::Tool but maintain thread safety by:
# 1. **No execution state in instance variables** - Only configuration
# 2. **All state passed through parameters** - ToolContext as first param
# 3. **Immutable tool instances** - Create once, use everywhere
# 4. **Stateless perform methods** - Pure functions with context input
#
# ## Why Thread Safety Matters
# In a multi-agent system, the same tool instance may be used concurrently by different
# agents running in separate threads or fibers. Storing execution state in instance
# variables would cause race conditions and data corruption.
#
# @example Defining a thread-safe tool
#   class WeatherTool < Agents::Tool
#     name "get_weather"
#     description "Get current weather for a location"
#     param :location, type: "string", desc: "City name or coordinates"
#
#     def perform(tool_context, location:)
#       # All state comes from parameters - no instance variables!
#       api_key = tool_context.context[:weather_api_key]
#       cache_duration = tool_context.context[:cache_duration] || 300
#
#       begin
#         # Make API call...
#         "Sunny, 72°F in #{location}"
#       rescue => e
#         "Weather service unavailable: #{e.message}"
#       end
#     end
#   end
#
module Agents
  class Tool < RubyLLM::Tool
    # Execute the tool with context injection.
    # This method is called by the runner and handles the thread-safe
    # execution pattern by passing all state through parameters.
    #
    # @param tool_context [Agents::ToolContext] The execution context containing shared state and usage tracking
    # @param params [Hash] Tool-specific parameters as defined by the tool's param declarations
    # @return [String] The tool's result
    def execute(tool_context, **params)
      perform(tool_context, **params)
    end

    # Perform the tool's action. Subclasses must implement this method.
    # This is where the actual tool logic lives. The method receives all
    # execution state through parameters, ensuring thread safety.
    #
    # @param tool_context [Agents::ToolContext] The execution context
    # @param params [Hash] Tool-specific parameters
    # @return [String] The tool's result
    # @raise [NotImplementedError] If not implemented by subclass
    # @example Implementing perform in a subclass
    #   class SearchTool < Agents::Tool
    #     def perform(tool_context, query:, max_results: 10)
    #       api_key = tool_context.context[:search_api_key]
    #       results = SearchAPI.search(query, api_key: api_key, limit: max_results)
    #       results.map(&:title).join("\n")
    #     end
    #   end
    def perform(tool_context, **params)
      raise NotImplementedError, "Tools must implement #perform(tool_context, **params)"
    end
  end
end
