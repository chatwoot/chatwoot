module AgentToolsResolvable
  extend ActiveSupport::Concern

  class_methods do
    def available_agent_tools
      @available_agent_tools ||= load_agent_tools
    end

    def resolve_tool_class(tool_id)
      class_name = "Captain::Tools::#{tool_id.classify}Tool"
      class_name.safe_constantize
    end

    private

    def load_agent_tools
      tools_config = YAML.load_file(Rails.root.join('config/agents/tools.yml'))

      tools_config.filter_map do |tool_config|
        tool_class = resolve_tool_class(tool_config['id'])

        if tool_class
          {
            id: tool_config['id'],
            title: tool_config['title'],
            description: tool_config['description'],
            icon: tool_config['icon']
          }
        else
          Rails.logger.warn "Tool class not found for ID: #{tool_config['id']}"
          nil
        end
      end
    end
  end
end