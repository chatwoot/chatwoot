# frozen_string_literal: true

# Prepends or replaces the system prompt in the message list.
# Optionally appends conversation context.
class Agent::Nodes::SystemPromptNode < BaseNode
  protected

  def process
    prompt = build_prompt
    apply_system_message(prompt)
    context.set_variable('system_prompt', prompt)

    { output: { prompt_length: prompt.length } }
  end

  private

  def build_prompt
    prompt = render_template(data['prompt_template'] || context.ai_agent.system_prompt)
    return prompt unless data['append_context'] && context.conversation

    prompt += "\n\nConversation context:\n"
    context.messages.last(5).each do |msg|
      prompt += "#{msg['role']}: #{msg['content']}\n"
    end
    prompt
  end

  def apply_system_message(prompt)
    context.messages.reject! { |m| m['role'] == 'system' }
    context.messages.unshift({ 'role' => 'system', 'content' => prompt })
  end
end
