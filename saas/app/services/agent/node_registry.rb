# frozen_string_literal: true

# Registry mapping node type strings to their handler classes.
# Each handler must implement `#execute(context)` and return `{ next_node_id: ... }`.
class Agent::NodeRegistry
  HANDLERS = {
    'trigger' => 'Agent::Nodes::TriggerNode',
    'system_prompt' => 'Agent::Nodes::SystemPromptNode',
    'knowledge_retrieval' => 'Agent::Nodes::KnowledgeRetrievalNode',
    'llm_call' => 'Agent::Nodes::LlmCallNode',
    'condition' => 'Agent::Nodes::ConditionNode',
    'loop' => 'Agent::Nodes::LoopNode',
    'set_variable' => 'Agent::Nodes::SetVariableNode',
    'delay' => 'Agent::Nodes::DelayNode',
    'http_request' => 'Agent::Nodes::HttpRequestNode',
    'handoff' => 'Agent::Nodes::HandoffNode',
    'reply' => 'Agent::Nodes::ReplyNode',
    'code' => 'Agent::Nodes::CodeNode'
  }.freeze

  def self.handler_for(node_type)
    klass_name = HANDLERS[node_type]
    raise ArgumentError, "Unknown node type: #{node_type}" unless klass_name

    klass_name.constantize
  end
end
