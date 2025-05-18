require 'openai'
class Captain::Agent
  attr_reader :name, :tools, :prompt, :persona, :goal, :secrets

  def initialize(name:, config:)
    @name = name
    @prompt = construct_prompt(config)
    @tools = prepare_tools(config[:tools] || [])
    @messages = config[:messages] || []
    @max_iterations = config[:max_iterations] || 10
    @llm = Captain::LlmService.new(api_key: config[:secrets][:OPENAI_API_KEY])
    @logger = Rails.logger

    @logger.info(@prompt)
  end

  def execute(input, context)
    setup_messages(input, context)
    result = {}
    @max_iterations.times do |iteration|
      push_to_messages(role: 'system', content: 'Provide a final answer') if iteration == @max_iterations - 1

      result = @llm.call(@messages, functions)
      handle_llm_result(result)

      break if result[:stop]
    end

    result[:output]
  end

  def register_tool(tool)
    @tools << tool
  end

  private

  def setup_messages(input, context)
    if @messages.empty?
      push_to_messages({ role: 'system', content: @prompt })
      push_to_messages({ role: 'assistant', content: context }) if context.present?
    end
    push_to_messages({ role: 'user', content: input })
  end

  def handle_llm_result(result)
    if result[:tool_call]
      tool_result = execute_tool(result[:tool_call])
      push_to_messages({ role: 'assistant', content: tool_result })
    else
      push_to_messages({ role: 'assistant', content: result[:output] })
    end
    result[:output]
  end

  def execute_tool(tool_call)
    function_name = tool_call['function']['name']
    arguments = JSON.parse(tool_call['function']['arguments'])

    tool = @tools.find { |t| t.name == function_name }
    tool.execute(arguments, {})
  rescue StandardError => e
    "Tool execution failed: #{e.message}"
  end

  def construct_prompt(config) # rubocop:disable Metrics/MethodLength
    return config[:prompt] if config[:prompt]

    <<~PROMPT
      Persona: #{config[:persona]}
      Objective: #{config[:goal]}

      Guidelines:
      - Persistently work towards achieving the stated objective without deviation.
      - Use only the provided tools to complete the task. Avoid inventing or assuming function names.
      - Set `'stop': true` once the objective is fully achieved.
      - DO NOT return tool usage as the final result.
      - If sufficient information is available to deliver result, compile and present it to the user.
      - Always return a final result and ENSURE the final result is formatted in Markdown.

      Output Structure:

      1. **Tool Usage:**
        - If a relevant function is identified, call it directly without unnecessary explanations.

      2. **Final Answer:**
        When ready to provide a complete response, follow this JSON format:

        ```json
        {
          "thought_process": "Explain the reasoning and steps taken to arrive at the final result.",
          "result": "Provide the complete response in clear, structured text.",
          "stop": true
        }
    PROMPT
  end

  def prepare_tools(tools = [])
    tools.map do |_, tool|
      Captain::Tool.new(
        name: tool['name'],
        config: {
          description: tool['description'],
          properties: tool['properties'],
          secrets: tool['secrets'],
          implementation: tool['implementation']
        }
      )
    end
  end

  def functions
    @tools.map do |tool|
      properties = {}
      tool.properties.each do |property_name, property_details|
        properties[property_name] = {
          type: property_details[:type],
          description: property_details[:description]
        }
      end
      required = tool.properties.select { |_, details| details[:required] == true }.keys
      {
        type: 'function',
        function: {
          name: tool.name,
          description: tool.description,
          parameters: { type: 'object', properties: properties, required: required }
        }
      }
    end
  end

  def push_to_messages(message)
    @logger.info("\n\n\nMessage: #{message}\n\n\n")
    @messages << message
  end
end
