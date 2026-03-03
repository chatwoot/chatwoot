# frozen_string_literal: true

# Orchestrates a multi-turn conversation with an AI agent.
# Handles: system prompt assembly, RAG context injection, tool-calling loop, and handoff.
#
# Usage:
#   executor = Agent::Executor.new(ai_agent: agent, conversation: conversation)
#   result = executor.execute(user_message: "How do I reset my password?")
#   result.reply        # => "To reset your password, go to..."
#   result.handed_off?  # => false
#   result.tool_calls   # => [{ name: "...", result: "..." }]
module Agent
  class Executor
    MAX_TOOL_ITERATIONS = 5

    ExecutionResult = Struct.new(:reply, :handed_off?, :tool_calls, :usage, keyword_init: true)

    def initialize(ai_agent:, conversation: nil, api_key: nil)
      @ai_agent = ai_agent
      @conversation = conversation
      @client = Llm::Client.new(model: ai_agent.model, api_key: api_key)
      @tool_runner = Agent::ToolRunner.new(ai_agent: ai_agent, conversation: conversation)
      @rag_service = Rag::SearchService.new(account: ai_agent.account, api_key: api_key) if ai_agent.has_knowledge?
      @executed_tools = []
    end

    def execute(user_message:, conversation_history: [], contact_context: nil)
      messages = build_messages(user_message, conversation_history, contact_context)
      tools = @ai_agent.tool_definitions

      iteration = 0
      total_usage = { 'prompt_tokens' => 0, 'completion_tokens' => 0, 'total_tokens' => 0 }

      loop do
        iteration += 1

        chat_options = {
          temperature: @ai_agent.temperature,
          max_tokens: @ai_agent.max_tokens,
          top_p: @ai_agent.top_p
        }
        chat_options[:tools] = tools if tools.present?

        response = @client.chat(messages: messages, **chat_options)
        choice = response.dig('choices', 0)
        message = choice&.dig('message')
        accumulate_usage(total_usage, response['usage'])

        # If the model wants to call tools
        tool_calls = message&.dig('tool_calls')
        if tool_calls.present? && iteration <= MAX_TOOL_ITERATIONS
          # Add the assistant's tool-calling message to history
          messages << message

          # Execute each tool call
          handed_off = false
          tool_calls.each do |tc|
            result = @tool_runner.run(tc)
            @executed_tools << { name: result.name, result: result.content }

            # Add tool result to messages
            messages << {
              role: 'tool',
              tool_call_id: tc['id'],
              content: result.content
            }

            if result.handoff?
              handed_off = true
              break
            end
          end

          if handed_off
            return ExecutionResult.new(
              reply: @executed_tools.last[:result],
              handed_off?: true,
              tool_calls: @executed_tools,
              usage: total_usage
            )
          end

          next # Let the model process tool results
        end

        # No tool calls or max iterations reached — return the reply
        reply = message&.dig('content') || ''
        return ExecutionResult.new(
          reply: reply,
          handed_off?: false,
          tool_calls: @executed_tools,
          usage: total_usage
        )
      end
    end

    private

    def build_messages(user_message, conversation_history, contact_context)
      messages = []

      # System prompt
      system_prompt = build_system_prompt(user_message, contact_context)
      messages << { role: 'system', content: system_prompt }

      # Conversation history (excludes the current message — it's added below)
      conversation_history.each do |msg|
        messages << { role: msg[:role] || msg['role'], content: msg[:content] || msg['content'] }
      end

      # Current user message
      messages << { role: 'user', content: user_message }

      messages
    end

    def build_system_prompt(user_message, contact_context = nil)
      # Prefer structured prompt sections over raw system_prompt
      sections_builder = Agent::PromptSectionsBuilder.new(@ai_agent)
      base_prompt = if sections_builder.sections?
                      sections_builder.build
                    else
                      @ai_agent.system_prompt.presence || default_system_prompt
                    end

      parts = [base_prompt]

      # Inject contact information so the AI knows who it's talking to
      parts << "## Informações do cliente\n#{contact_context}" if contact_context.present?

      # Inject RAG context if available
      if @rag_service
        context = @rag_service.build_context(ai_agent: @ai_agent, query: user_message)
        parts << context if context.present?
      end

      # Add handoff tool instruction if agent has tools
      if @ai_agent.agent_tools.active.any?
        parts << 'You have access to tools. Use them when needed to answer questions or perform actions. ' \
                 'If you cannot help the customer, use the handoff_to_human tool.'
      end

      # Reaction instruction: let the LLM naturally decide when to react
      parts << reaction_instruction

      parts.join("\n\n")
    end

    def reaction_instruction
      <<~INSTRUCTION.strip
        ## Reações em mensagens
        Quando a mensagem do cliente expressar uma emoção, saudação, agradecimento, humor ou algo que mereça uma reação \
        natural, você pode OPCIONALMENTE iniciar sua resposta com [REACT:emoji] usando um único emoji apropriado. \
        Exemplos: [REACT:😊], [REACT:👍], [REACT:❤️], [REACT:😂], [REACT:🙏].
        NÃO reaja em todas as mensagens — apenas quando for natural e humano reagir. \
        Nunca reaja a perguntas simples, informações ou mensagens neutras. \
        O [REACT:emoji] será removido da resposta antes de enviá-la ao cliente.
      INSTRUCTION
    end

    def default_system_prompt
      'You are a helpful customer support AI assistant. Be concise, accurate, and friendly.'
    end

    def accumulate_usage(total, usage)
      return unless usage

      total['prompt_tokens'] += usage['prompt_tokens'].to_i
      total['completion_tokens'] += usage['completion_tokens'].to_i
      total['total_tokens'] += usage['total_tokens'].to_i
    end
  end
end
