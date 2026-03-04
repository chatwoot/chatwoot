# frozen_string_literal: true

# Entry point of every workflow. Seeds the user_message variable and passes through.
class Agent::Nodes::TriggerNode < Agent::Nodes::BaseNode
  protected

  def process
    # The trigger node just passes through — user_message is already seeded by WorkflowExecutor
    context.set_variable('trigger_type', data['trigger_type'] || 'message_received')
    { output: { trigger_type: data['trigger_type'] } }
  end
end
