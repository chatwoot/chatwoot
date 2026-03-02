# frozen_string_literal: true

# Base class for all workflow node handlers.
# Subclasses implement `#process` and return a result hash.
# The base class provides common helpers: data access, handle resolution, logging.
class Agent::Nodes::BaseNode
  attr_reader :node_config, :context, :edges

  # @param node_config [Hash] The node definition from the workflow JSON (id, type, data, position)
  # @param context [Agent::RunContext] Mutable run state
  # @param edges [Array<Hash>] All edges in the workflow for handle resolution
  def initialize(node_config:, context:, edges:)
    @node_config = node_config
    @context = context
    @edges = edges
  end

  def execute
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    result = process
    duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round

    context.log_execution(
      node_id: node_id,
      node_type: node_type,
      status: 'completed',
      duration_ms: duration,
      output: result[:output],
      tokens: result[:tokens]
    )

    { next_node_id: resolve_next_node(result[:handle] || 'flow_out'), output: result[:output] }
  rescue StandardError => e
    duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round
    context.log_execution(
      node_id: node_id,
      node_type: node_type,
      status: 'failed',
      duration_ms: duration,
      error: e.message
    )
    raise
  end

  protected

  # Subclasses implement this. Return { output: ..., handle: 'flow_out', tokens: nil }
  def process
    raise NotImplementedError, "#{self.class.name}#process must be implemented"
  end

  def node_id
    node_config['id']
  end

  def node_type
    node_config['type']
  end

  def data
    node_config['data'] || {}
  end

  # Render a Liquid template string with the current context variables
  def render_template(template_str)
    return template_str if template_str.blank?

    liquid = Liquid::Template.parse(template_str)
    liquid.render(context.variables)
  end

  private

  # Follow the outgoing edge from the given source handle to find the next node
  def resolve_next_node(handle_id)
    edge = edges.find { |e| e['source'] == node_id && e['source_handle'] == handle_id }
    edge&.dig('target')
  end
end
