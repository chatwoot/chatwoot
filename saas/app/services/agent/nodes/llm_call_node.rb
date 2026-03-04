# frozen_string_literal: true

# Calls the LLM with the current message history.
# Supports optional tool calling with iteration loop.
class Agent::Nodes::LlmCallNode < Agent::Nodes::BaseNode
  MAX_TOOL_ITERATIONS = 5

  protected

  def process
    model = data['model'] || context.ai_agent.model
    client = Llm::Client.new(model: model)

    chat_options = {
      temperature: data['temperature'] || context.ai_agent.temperature,
      max_tokens: data['max_tokens'] || context.ai_agent.max_tokens,
      top_p: context.ai_agent.top_p
    }

    # Include tools if enabled
    tools = context.ai_agent.tool_definitions if data['tools_enabled']
    chat_options[:tools] = tools if tools.present?
    chat_options[:tool_choice] = data['tool_choice'] if data['tool_choice'].present?

    total_tokens = 0
    iteration = 0
    reply = nil

    loop do
      iteration += 1

      response = client.chat(messages: context.messages, **chat_options)
      usage = response['usage']
      total_tokens += usage['total_tokens'] if usage

      choice = response.dig('choices', 0)
      message = choice&.dig('message')

      tool_calls = message&.dig('tool_calls')
      if tool_calls.present? && iteration <= MAX_TOOL_ITERATIONS
        context.messages << message
        tool_runner = Agent::ToolRunner.new(ai_agent: context.ai_agent, conversation: context.conversation)

        tool_calls.each do |tc|
          result = tool_runner.run(tc)
          context.add_message(role: 'tool', content: result.content, tool_call_id: tc['id'], name: result.name)
        end

        next
      end

      reply = message&.dig('content')
      context.add_message(role: 'assistant', content: reply) if reply
      break
    end

    context.set_variable('llm_reply', reply)
    { output: { reply_length: reply&.length, iterations: iteration }, tokens: total_tokens }
  end
end
