module Concerns::McpToolable
  extend ActiveSupport::Concern

  def build_tool_instance(assistant, tool_name)
    tool_def = cached_tools.find { |t| t['name'] == tool_name }
    return nil unless tool_def

    mcp_server = self
    class_name = "#{slug.underscore.camelize}#{tool_name.underscore.camelize}"

    tool_class = Class.new(Captain::Tools::McpTool) do
      description tool_def['description'] || "MCP tool: #{tool_name}"

      (tool_def.dig('inputSchema', 'properties') || {}).each do |param_name, param_schema|
        required = tool_def.dig('inputSchema', 'required')&.include?(param_name) || false
        param param_name.to_sym,
              type: param_schema['type'] || 'string',
              desc: param_schema['description'] || param_name,
              required: required
      end
    end

    Captain::Tools.send(:remove_const, class_name) if Captain::Tools.const_defined?(class_name, false)
    Captain::Tools.const_set(class_name, tool_class)

    tool_class.new(assistant, mcp_server, tool_name)
  end

  def build_auth_headers
    case auth_type
    when 'bearer'
      { 'Authorization' => "Bearer #{auth_config['token']}" }
    when 'api_key'
      header_name = auth_config['header_name'] || 'X-API-Key'
      { header_name => auth_config['key'] }
    else
      {}
    end
  end
end
