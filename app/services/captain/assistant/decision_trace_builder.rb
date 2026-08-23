# frozen_string_literal: true

# Captures the observable decision trail of a single agent run by subscribing to
# the ai-agents runner's callbacks. Produces an ordered list of nodes that mirrors
# how the LLM actually reasoned: which agent was activated, what it was told, which
# tool it invoked (with arguments and result), which agent it handed off to, and
# what it finally replied. This is used by the playground to render a live decision
# tree and by the conversation pipeline to persist a debug trace per real chat run.
class Captain::Assistant::DecisionTraceBuilder
  NODE_TYPES = {
    agent_activated: 'agent_activated',
    tool_call: 'tool_call',
    tool_result: 'tool_result',
    agent_handoff: 'agent_handoff',
    final_response: 'final_response'
  }.freeze

  CONTINUING_CONVERSATION_INPUT = '(continuing conversation)'

  attr_reader :nodes

  def initialize(assistant:)
    @assistant = assistant
    @nodes = []
  end

  # Subscribe the collector to the runner's callbacks. Every callback appends a
  # node so the resulting list is a faithful, ordered replay of the decision.
  def install(runner)
    runner.on_agent_thinking { |agent_name, input, context_wrapper| record_agent_activation(agent_name, input, context_wrapper) }
    runner.on_tool_start { |tool_name, args, context_wrapper| record_tool_call(tool_name, args, context_wrapper) }
    runner.on_tool_complete { |tool_name, result, context_wrapper| record_tool_result(tool_name, result, context_wrapper) }
    runner.on_agent_handoff { |from_agent, to_agent, reason, context_wrapper| record_handoff(from_agent, to_agent, reason, context_wrapper) }
    runner.on_run_complete { |_agent_name, result, _context_wrapper| record_final_response(result) }
    runner
  end

  def reset!
    @nodes = []
  end

  def to_h
    @nodes
  end

  private

  def record_agent_activation(agent_name, input, _context_wrapper)
    return if input.to_s == CONTINUING_CONVERSATION_INPUT

    @nodes << {
      'type' => NODE_TYPES[:agent_activated],
      'agent' => humanized_agent_name(agent_name),
      'agent_key' => agent_name.to_s,
      'input' => truncate(input_text(input))
    }
  end

  def record_tool_call(tool_name, args, _context_wrapper)
    @nodes << {
      'type' => NODE_TYPES[:tool_call],
      'tool' => tool_name.to_s,
      'arguments' => args
    }
  end

  def record_tool_result(tool_name, result, _context_wrapper)
    @nodes << {
      'type' => NODE_TYPES[:tool_result],
      'tool' => tool_name.to_s,
      'result' => truncate(result.to_s)
    }
  end

  def record_handoff(from_agent, to_agent, reason, _context_wrapper)
    @nodes << {
      'type' => NODE_TYPES[:agent_handoff],
      'from_agent' => humanized_agent_name(from_agent),
      'from_agent_key' => from_agent.to_s,
      'to_agent' => humanized_agent_name(to_agent),
      'to_agent_key' => to_agent.to_s,
      'reason' => reason.to_s
    }
  end

  def record_final_response(result)
    return if result.nil?

    @nodes << {
      'type' => NODE_TYPES[:final_response],
      'agent' => humanized_agent_name(result.context&.dig(:current_agent)),
      'response' => truncate(extract_response_text(result))
    }
  end

  def input_text(input)
    input.is_a?(RubyLLM::Content) ? input.text.to_s : input.to_s
  end

  def extract_response_text(result)
    output = result.output
    return output.to_s unless output.is_a?(Hash)

    response_parts = output['response_parts']
    return Array(response_parts).pluck('text').join("\n\n") if response_parts.present?

    output['response'].to_s
  end

  # Scenario agents are named like "scenario_12_refund_agent". Surface a readable
  # label ("Scenario: Refund") while keeping the raw key for reference. Titles are
  # loaded once into a lookup map so multiple handoff nodes in a run don't issue a
  # query each.
  def humanized_agent_name(agent_name)
    raw_name = agent_name.to_s
    match = raw_name.match(/\A#{Captain::Scenario::HANDOFF_KEY_PREFIX}_(\d+)_(.+)_#{Captain::Scenario::HANDOFF_KEY_SUFFIX}\z/o)
    return raw_name unless match

    scenario_id, slug = match.captures
    title = scenario_titles_by_id[scenario_id.to_i]
    title.presence || slug.tr('_', ' ').capitalize
  end

  def scenario_titles_by_id
    @scenario_titles_by_id ||= @assistant.scenarios.pluck(:id, :title).to_h
  end

  def truncate(text, limit = 2000)
    return text if text.length <= limit

    "#{text.first(limit)}…[truncated]"
  end
end
