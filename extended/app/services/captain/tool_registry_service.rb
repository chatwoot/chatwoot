module Captain
  class ToolRegistryService
    attr_reader :tools, :registered_tools

    def initialize(assistant, user: nil)
      @assistant = assistant
      @user = user
      @tools = {}
      @registered_tools = []
    end

    def register_tool(tool_class)
      tool_instance = tool_class.new(@assistant, user: @user)
      return unless tool_instance.active?

      store_tool(tool_instance)
    end

    def tools_summary
      @tools.values.map { |tool| "- #{tool.name}: #{tool.description}" }.join("\n")
    end

    def method_missing(method_name, *, **)
      tool_name = method_name.to_s
      if @tools.key?(tool_name)
        @tools[tool_name].execute(*, **)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @tools.key?(method_name.to_s) || super
    end

    private

    def store_tool(tool)
      @tools[tool.name] = tool
      @registered_tools << format_for_registry(tool)
    end

    def format_for_registry(tool)
      # If the tool already provides the full structure, use it.
      # Otherwise, wrap it in the OpenAI function format.
      definition = tool.to_registry_format

      if definition.key?(:type) && definition[:type] == 'function'
        definition
      else
        { type: 'function', function: definition }
      end
    end
  end
end
