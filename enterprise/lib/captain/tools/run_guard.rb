# frozen_string_literal: true

# Runtime protection against runaway tool-call loops in a Captain V2 generation.
#
# RubyLLM::Chat#handle_tool_calls recurses back into #complete after every tool
# result, so a model that keeps asking for tools never returns control to
# Agents::Runner and its max_turns budget is never evaluated. A tool can only
# break that recursion by returning a RubyLLM::Tool::Halt, so this guard both
# builds those halts for terminal conditions and caps how many tool calls a
# single generation may execute.
#
# Counters live in the run state hash, which AgentRunnerService rebuilds for every
# generation, so nothing is shared between conversations or Sidekiq threads.
class Captain::Tools::RunGuard
  # Legitimate flows chain a handful of lookups with a few mutations. Anything
  # beyond this is a loop, not a plan.
  MAX_TOOL_CALLS_PER_RUN = 20
  MAX_IDENTICAL_TOOL_CALLS = 3

  HALT_REASON_KEY = :captain_v2_halt_reason
  TOOL_CALLS_KEY = :captain_v2_tool_calls

  HANDOFF_COMPLETED = 'handoff_completed'
  STALE_RUN = 'stale_run'
  TOOL_CALL_BUDGET_EXCEEDED = 'tool_call_budget_exceeded'

  BUDGET_EXCEEDED_MESSAGE = "Run stopped: the maximum of #{MAX_TOOL_CALLS_PER_RUN} tool calls for this message was reached.".freeze
  REPEATED_CALL_MESSAGE = 'Tool call skipped: this tool already ran with the same arguments ' \
                          "#{MAX_IDENTICAL_TOOL_CALLS} times for this message. Do not call it again, " \
                          'answer the customer with the information you already have.'.freeze

  def self.halt_reason(state)
    state&.dig(HALT_REASON_KEY)
  end

  def initialize(state)
    @state = state || {}
  end

  # Records a tool call and reports whether the tool is still allowed to run.
  #
  # @return [Symbol] :allowed, :repeated when the same call was already made too
  #   often, or :exhausted when the run consumed its whole tool budget
  def register_call(tool_name, params)
    counters = (@state[TOOL_CALLS_KEY] ||= { total: 0, signatures: {} })
    counters[:total] += 1

    signature = signature_for(tool_name, params)
    counters[:signatures][signature] = counters[:signatures].fetch(signature, 0) + 1

    return :exhausted if counters[:total] > MAX_TOOL_CALLS_PER_RUN
    return :repeated if counters[:signatures][signature] > MAX_IDENTICAL_TOOL_CALLS

    :allowed
  end

  def total_calls
    @state.dig(TOOL_CALLS_KEY, :total) || 0
  end

  # Ends the LLM tool loop and records why, so AgentRunnerService can tell an
  # interrupted run apart from a model-authored answer.
  def halt(reason, message)
    @state[HALT_REASON_KEY] = reason
    RubyLLM::Tool::Halt.new(message)
  end

  private

  # Digest keeps the state small while staying stable across processes, unlike
  # Object#hash which is seeded per process.
  def signature_for(tool_name, params)
    normalized = params.sort_by { |key, _value| key.to_s }.map { |key, value| [key.to_s, value.to_s.strip.downcase] }

    Digest::SHA256.hexdigest([tool_name.to_s, normalized].to_json)
  end
end
