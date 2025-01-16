class Captain::Copilot::ChatService
  def initialize(assistant, config)
    @assistant = assistant
    @conversation_history = config[:conversation_history]
    @previous_messages = config[:previous_messages]
    build_agent
    register_search_documentation
  end

  def execute(input)
    @agent.execute(input, conversation_history_context)
  end

  private

  def build_agent
    @agent = Captain::Agent.new(
      name: 'Support Copilot',
      config: {
        description: 'an AI assistant helping support agents',
        messages: @previous_messages,
        persona: 'You are an AI copilot for customer support agents',
        goal: "
          Your goal is help the support agents with meaningful responses based on the knowledge you have
          and you can gather using tools provided about the product or service.
        ",
        secrets: {
          OPENAI_API_KEY: InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value
        },
        max_iterations: 2
      }
    )
  end

  def conversation_history_context
    "
    Message History with the user is below:
    #{@conversation_history}
    "
  end

  def register_search_documentation
    tool = Captain::Tool.new(
      name: 'search_documentation',
      config: {
        description: "Use this function to get documentation on functionalities you don't know about.",
        properties: {
          search_query: {
            type: 'string',
            description: 'The search query to look up in the documentation.',
            required: true
          }
        },
        memory: {
          assistant_id: @assistant.id,
          account_id: @assistant.account_id
        }
      }
    )

    register_tool tool
  end

  def register_tool(tool)
    tool.register_method do |inputs, _, memory|
      assistant = Captain::Assistant.find(memory[:assistant_id])
      assistant
        .responses
        .approved
        .search(inputs['search_query'])
        .map do |response|
        "\n\nQuestion: #{response[:question]}\nAnswer: #{response[:answer]}"
      end.join
    end

    @agent.register_tool tool
  end
end
