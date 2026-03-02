# frozen_string_literal: true

# Holds mutable state during a single workflow run.
# Passed to each node handler so they can read/write variables, messages, and log execution steps.
#
# Usage:
#   ctx = Agent::RunContext.new(ai_agent: agent, conversation: conv, workflow_run: run)
#   ctx.set_variable('name', 'Alice')
#   ctx.get_variable('name')  # => 'Alice'
#   ctx.add_message(role: 'user', content: 'Hello')
class Agent::RunContext
  attr_reader :ai_agent, :conversation, :workflow_run, :variables, :messages
  attr_accessor :handed_off, :final_reply

  def initialize(ai_agent:, conversation:, workflow_run:)
    @ai_agent = ai_agent
    @conversation = conversation
    @workflow_run = workflow_run
    @variables = (workflow_run.variables || {}).dup
    @messages = (workflow_run.messages || []).dup
    @handed_off = false
    @final_reply = nil
  end

  def set_variable(key, value)
    @variables[key.to_s] = value
  end

  def get_variable(key)
    @variables[key.to_s]
  end

  def add_message(role:, content:, **attrs)
    @messages << { 'role' => role, 'content' => content }.merge(attrs.stringify_keys)
  end

  def log_execution(attrs = {})
    entry = {
      node_id: attrs[:node_id],
      node_type: attrs[:node_type],
      status: attrs[:status],
      duration_ms: attrs[:duration_ms] || 0,
      timestamp: Time.current.iso8601
    }
    entry[:output] = attrs[:output] if attrs[:output]
    entry[:error] = attrs[:error] if attrs[:error]
    entry[:tokens] = attrs[:tokens] if attrs[:tokens]

    workflow_run.execution_log << entry
  end

  def persist!
    workflow_run.update!(
      variables: @variables,
      messages: @messages
    )
  end
end
