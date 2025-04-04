class Captain::Llm::AssistantChatService < Llm::BaseService
  def initialize(assistant: nil)
    super()
    @assistant = assistant
    search_tool = Captain::Tools::DocumentationSearch.new(assistant)
    @chat = ::RubyLLM.chat(model: @model).with_tool(search_tool)
    @chat.with_instructions(system_message)
  end

  def generate_response(input, previous_messages = [], _role = 'user')
    previous_messages.each do |msg|
      @chat.add_message(role: msg[:role], content: msg[:content])
    end

    response = @chat.ask(input) if input.present?
    format_response(response)
  end

  private

  def system_message
    Captain::Llm::SystemPromptsService.assistant_response_generator(@assistant.config['product_name'])
  end

  def format_response(response)
    return '' if response.nil?

    content = response.content
    return 'conversation_handoff' if content.include?('conversation_handoff')

    begin
      ::JSON.parse(content)
    rescue ::JSON::ParserError
      content
    end
  end
end
