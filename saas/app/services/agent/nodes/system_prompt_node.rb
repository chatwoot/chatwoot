# frozen_string_literal: true

# Prepends or replaces the system prompt in the message list.
# Optionally appends conversation context.
class Agent::Nodes::SystemPromptNode < Agent::Nodes::BaseNode
  protected

  def process
    prompt = build_prompt
    apply_system_message(prompt)
    context.set_variable('system_prompt', prompt)

    { output: { prompt_length: prompt.length } }
  end

  private

  def build_prompt
    template = data['prompt_template']

    # If no explicit template, try structured prompt sections, then fall back to system_prompt
    if template.blank?
      sections_builder = Agent::PromptSectionsBuilder.new(context.ai_agent)
      prompt = if sections_builder.sections?
                 sections_builder.build
               else
                 context.ai_agent.system_prompt || ''
               end
    else
      prompt = render_template(template)
    end

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
