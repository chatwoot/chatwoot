module Captain
  module Llm
    class AssistantChatService
      def initialize(assistant:, conversation_id: nil)
        @assistant = assistant
        @conversation_id = conversation_id
        @llm = Captain::LlmService.new(api_key: ENV.fetch('OPENAI_API_KEY', nil)) # Or from assistant config
        @tool_registry = Captain::ToolRegistryService.new(@assistant)
        setup_tools
      end

      def generate_response(additional_message: nil, message_history: [], role: 'user')
        messages = prepare_messages(additional_message, message_history, role)

        response = @llm.call(messages, @tool_registry.registered_tools)

        # Handle tool calls if any (simple implementation for now)
        if response[:tool_call]
          handle_tool_call(response[:tool_call], messages)
        else
          response[:output]
        end
      end

      private

      def setup_tools
        @tool_registry.register_tool(Captain::Tools::SearchDocumentationService)
      end

      def prepare_messages(new_msg, history, role)
        msgs = [{ role: 'system', content: system_prompt }]
        msgs += history
        msgs << { role: role, content: new_msg } if new_msg.present?
        msgs
      end

      def system_prompt
        Captain::Llm::SystemPromptsService.assistant_response_generator(
          @assistant.name,
          @assistant.config['product_name'],
          @assistant.config
        )
      end

      def handle_tool_call(tool_call, messages)
        # Execute tool
        function = tool_call['function']
        name = function['name']
        args = JSON.parse(function['arguments'])

        result = @tool_registry.send(name, args)

        # Append result and recurse (one turn for now)
        messages << { role: 'assistant', content: nil, tool_calls: [tool_call] }
        messages << { role: 'tool', tool_call_id: tool_call['id'], name: name, content: result.to_json }

        final_response = @llm.call(messages, @tool_registry.registered_tools)
        final_response[:output]
      end
    end
  end
end
