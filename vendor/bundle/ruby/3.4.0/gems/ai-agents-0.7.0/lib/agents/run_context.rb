# frozen_string_literal: true

# RunContext encapsulates the execution context and usage metrics for a single agent run.
# It provides isolation between concurrent executions by giving each run its own context
# copy and tracking token usage throughout the execution. This is a key component in
# ensuring thread safety.
#
# @example Creating a RunContext for an agent execution
#   context_data = { user_id: 123, session: "abc" }
#   run_context = Agents::RunContext.new(context_data)
#
#   # Access context during execution
#   user_id = run_context.context[:user_id]
#
#   # Track usage after LLM calls
#   run_context.usage.add(llm_response.usage)
#
# @example Tracking token usage across multiple LLM calls
#   run_context = Agents::RunContext.new({})
#
#   # First LLM call
#   response1 = llm.complete(prompt1)
#   run_context.usage.add(response1.usage)
#
#   # Second LLM call
#   response2 = llm.complete(prompt2)
#   run_context.usage.add(response2.usage)
#
#   # Total usage is automatically accumulated
#   puts "Total tokens: #{run_context.usage.total_tokens}"
#
# @example Thread safety through context isolation
#   # Shared configuration (never modified)
#   base_context = { api_key: "secret", model: "gpt-4" }
#
#   # Concurrent agent runs using Async
#   Async do
#     5.times.map do |i|
#       Async do
#         # Each run gets its own context COPY
#         run_context = Agents::RunContext.new(base_context.dup)
#
#         # Safe to modify - changes are isolated to this run
#         run_context.context[:user_id] = i
#         run_context.context[:session] = "session_#{i}"
#
#         # Other concurrent runs cannot see these changes
#         puts "Run #{i}: user_id = #{run_context.context[:user_id]}"
#       end
#     end.map(&:wait)
#   end
#
#   # Key points:
#   # - base_context remains unmodified
#   # - Each run has isolated context via .dup
#   # - No race conditions or data leakage between runs
module Agents
  class RunContext
    attr_reader :context, :usage, :callbacks, :callback_manager

    # Initialize a new RunContext with execution context and usage tracking
    #
    # @param context [Hash] The execution context data (will be duplicated for isolation)
    # @param callbacks [Hash] Optional callbacks for real-time event notifications
    def initialize(context, callbacks: {})
      @context = context
      @usage = Usage.new
      @callbacks = callbacks || {}
      @callback_manager = CallbackManager.new(@callbacks)
    end

    # Usage tracks token consumption across all LLM calls within a single run.
    # This is very rudimentary usage reporting.
    # We can use this further for billing purposes, but is not a replacement for tracing.
    #
    # @example Accumulating usage from multiple LLM calls
    #   usage = Agents::RunContext::Usage.new
    #
    #   # Add usage from first call
    #   usage.add(OpenStruct.new(input_tokens: 100, output_tokens: 50, total_tokens: 150))
    #
    #   # Add usage from second call
    #   usage.add(OpenStruct.new(input_tokens: 200, output_tokens: 100, total_tokens: 300))
    #
    #   puts usage.total_tokens  # => 450
    class Usage
      attr_accessor :input_tokens, :output_tokens, :total_tokens

      # Initialize a new Usage tracker with all counters at zero
      def initialize
        @input_tokens = 0
        @output_tokens = 0
        @total_tokens = 0
      end

      # Add usage metrics from an LLM response to the running totals.
      # Safely handles nil values in the usage object.
      #
      # @param usage [Object] An object responding to input_tokens, output_tokens, and total_tokens
      # @example Adding usage from an LLM response
      #   usage.add(llm_response.usage)
      def add(usage)
        @input_tokens += usage.input_tokens || 0
        @output_tokens += usage.output_tokens || 0
        @total_tokens += usage.total_tokens || 0
      end
    end
  end
end
