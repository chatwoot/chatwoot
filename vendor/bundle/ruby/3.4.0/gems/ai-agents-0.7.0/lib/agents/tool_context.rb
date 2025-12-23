# frozen_string_literal: true

# ToolContext provides tools with controlled access to execution state during their invocation.
# It wraps the RunContext and adds tool-specific metadata like retry count. This is a critical
# component of the thread-safe design - tools receive all their execution state through this
# context object rather than storing it in instance variables.
#
# @example Tool receiving context during execution
#   class CalculatorTool < Agents::Tool
#     def perform(tool_context, expression:)
#       # Access shared context data
#       precision = tool_context.context[:precision] || 2
#
#       # Track retry attempts
#       if tool_context.retry_count > 0
#         logger.warn "Retrying calculation (attempt #{tool_context.retry_count + 1})"
#       end
#
#       result = eval(expression)
#       result.round(precision)
#     end
#   end
#
# @example Runner creating ToolContext for execution
#   run_context = Agents::RunContext.new({ user: current_user })
#   tool_context = Agents::ToolContext.new(
#     run_context: run_context,
#     retry_count: 0
#   )
#
#   result = tool.execute(tool_context, expression: "2 + 2")
#
# ## How Thread Safety is Ensured
#
# ToolContext enables thread-safe tool execution by enforcing a critical principle:
# all execution state must flow through method parameters, never through instance variables.
#
# Here's how it works:
#
# 1. **Tool instances are stateless** - They only store configuration (name, description),
#    never execution data like current user, session, or request details.
#
# 2. **State flows through parameters** - When a tool is executed, it receives a ToolContext
#    parameter that contains all the execution-specific state it needs.
#
# 3. **Each execution is isolated** - Multiple threads can call the same tool instance
#    simultaneously, but each call gets its own ToolContext with its own state.
#
# This is similar to how web frameworks handle concurrent requests - the controller
# instance might be shared, but each request gets its own params and session objects.
# The ToolContext serves the same purpose, providing isolation without requiring
# new object creation for each execution.
module Agents
  class ToolContext
    attr_reader :run_context, :retry_count

    # Initialize a new ToolContext wrapping a RunContext
    #
    # @param run_context [Agents::RunContext] The run context containing shared execution state
    # @param retry_count [Integer] Number of times this tool execution has been retried (default: 0)
    def initialize(run_context:, retry_count: 0)
      @run_context = run_context
      @retry_count = retry_count
    end

    # Convenient access to the shared context hash from the RunContext.
    # This delegation makes it easier for tools to access context data without
    # having to navigate through run_context.context.
    #
    # @return [Hash] The shared context hash from the RunContext
    # @example Accessing context data in a tool
    #   def perform(tool_context, **params)
    #     user_id = tool_context.context[:user_id]
    #     session = tool_context.context[:session]
    #     # ...
    #   end
    def context
      @run_context.context
    end

    # Convenient access to the usage tracking object from the RunContext.
    # Tools can use this to add their own usage metrics if they make
    # additional LLM calls.
    #
    # @return [Agents::RunContext::Usage] The usage tracking object
    # @example Tool tracking additional LLM usage
    #   def perform(tool_context, **params)
    #     # Tool makes its own LLM call
    #     response = llm.complete("Analyze: #{params[:data]}")
    #     tool_context.usage.add(response.usage)
    #
    #     response.content
    #   end
    def usage
      @run_context.usage
    end

    # Convenient access to the shared state hash within the context.
    # This provides tools with a dedicated space to store and retrieve
    # state that persists across agent interactions within a conversation.
    #
    # State is automatically initialized as an empty hash if it doesn't exist.
    # All state modifications are automatically included in context serialization,
    # making it persist across process boundaries (e.g., Rails with ActiveRecord).
    #
    # @return [Hash] The shared state hash
    # @example Tool storing customer information in state
    #   def perform(tool_context, customer_id:)
    #     customer = Customer.find(customer_id)
    #
    #     # Store in shared state for other tools/agents to access
    #     tool_context.state[:customer_id] = customer_id
    #     tool_context.state[:customer_name] = customer.name
    #     tool_context.state[:plan_type] = customer.plan
    #
    #     "Found customer #{customer.name}"
    #   end
    #
    # @example Tool reading from shared state
    #   def perform(tool_context)
    #     customer_id = tool_context.state[:customer_id]
    #     plan_type = tool_context.state[:plan_type]
    #
    #     if customer_id && plan_type
    #       "Current plan: #{plan_type} for customer #{customer_id}"
    #     else
    #       "No customer information available"
    #     end
    #   end
    def state
      context[:state] ||= {}
    end
  end
end
