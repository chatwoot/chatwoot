# frozen_string_literal: true

# Iterates over an array variable, executing the loop body for each item.
# Exposes `loop_item`, `loop_index`, and `loop_count` variables.
# Routes to 'flow_body' for each iteration and 'flow_done' when complete.
class Agent::Nodes::LoopNode < Agent::Nodes::BaseNode
  protected

  def process
    source = data['source_variable'] || 'items'
    items = context.get_variable(source)
    items = Array.wrap(items)
    max_iterations = data['max_iterations'] || 10
    items = items.first(max_iterations)

    context.set_variable('loop_count', items.size)
    context.set_variable('loop_items', items)

    # For the graph executor, loops are simplified:
    # we set the variables and let the flow continue.
    # Full iteration requires the executor to support re-entry (future enhancement).
    if items.any?
      context.set_variable('loop_item', items.first)
      context.set_variable('loop_index', 0)
    end

    handle = items.any? ? 'flow_body' : 'flow_done'
    { output: { items_count: items.size }, handle: handle }
  end
end
