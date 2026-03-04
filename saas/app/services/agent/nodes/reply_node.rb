# frozen_string_literal: true

# Sends a reply message to the conversation.
# Supports text replies and Liquid template replies.
# Optionally uses the LLM reply variable as content.
class Agent::Nodes::ReplyNode < Agent::Nodes::BaseNode
  protected

  def process
    content = build_content
    return { output: { skipped: true } } if content.blank?

    context.conversation&.messages&.create!(
      content: content,
      message_type: :outgoing,
      account_id: context.ai_agent.account_id,
      inbox_id: context.conversation.inbox_id,
      content_attributes: {
        ai_generated: true,
        ai_agent_id: context.ai_agent.id
      }
    )

    context.final_reply = content
    context.set_variable('last_reply', content)

    { output: { content_length: content.length } }
  end

  private

  def build_content
    case data['message_type']
    when 'template'
      render_template(data['content_template'])
    else
      # Use LLM reply or direct content
      data['content_template'].present? ? render_template(data['content_template']) : context.get_variable('llm_reply')
    end
  end
end
