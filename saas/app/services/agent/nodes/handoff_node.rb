# frozen_string_literal: true

# Hands off the conversation to a human agent.
# Sets the conversation status to open/pending and stops the workflow.
class Agent::Nodes::HandoffNode < Agent::Nodes::BaseNode
  protected

  def process
    reason = render_template(data['reason_template'] || '')

    context.conversation&.update!(
      status: :open,
      assignee_id: nil
    )

    context.handed_off = true
    context.set_variable('handoff_reason', reason)

    { output: { reason: reason } }
  end
end
