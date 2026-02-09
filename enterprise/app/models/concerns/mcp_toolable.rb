module Concerns::McpToolable
  extend ActiveSupport::Concern

  def build_tool_instance(assistant, tool_name)
    tool_def = cached_tools.find { |t| t['name'] == tool_name }
    return nil unless tool_def

    tool_class = create_tool_class(tool_name, tool_def)
    tool_class.new(assistant, self, tool_name)
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

  private

  def create_tool_class(tool_name, tool_def)
    class_name = "#{slug.underscore.camelize}#{tool_name.underscore.camelize}"
    tool_class = build_dynamic_tool_class(tool_name, tool_def)
    register_tool_class(class_name, tool_class)
    tool_class
  end

  def build_dynamic_tool_class(tool_name, tool_def)
    mcp_tool_name = build_tool_function_name(tool_name)
    tool_description = tool_def['description'] || "MCP tool: #{tool_name}"
    param_definitions = extract_param_definitions(tool_def)

    Class.new(Captain::Tools::McpTool) do
      description tool_description
      define_method(:name) { mcp_tool_name }

      param_definitions.each do |param_def|
        param param_def[:name], type: param_def[:type], desc: param_def[:desc], required: param_def[:required]
      end
    end
  end

  # RubyLLM::Parameter only supports simple scalar types (string, integer, number, boolean).
  # Complex types like array/object produce invalid JSON schemas (e.g. array missing `items`).
  # Coerce unsupported types to string so the LLM receives a valid schema.
  SUPPORTED_PARAM_TYPES = %w[string integer number boolean].freeze

  def extract_param_definitions(tool_def)
    properties = tool_def.dig('inputSchema', 'properties') || {}
    required_params = tool_def.dig('inputSchema', 'required') || []

    properties.map do |param_name, param_schema|
      raw_type = param_schema['type'] || 'string'
      {
        name: param_name.to_sym,
        type: SUPPORTED_PARAM_TYPES.include?(raw_type) ? raw_type : 'string',
        desc: param_schema['description'] || param_name,
        required: required_params.include?(param_name)
      }
    end
  end

  def build_tool_function_name(tool_name)
    # Build a compliant function name: max 64 chars, alphanumeric + underscore/hyphen
    # Format: mcp_{short_slug}_{tool_name}, truncated if needed
    short_slug = slug.sub(/^mcp_/, '')[0, 20]
    base_name = "mcp_#{short_slug}_#{tool_name}"
    base_name[0, 64]
  end

  def register_tool_class(class_name, tool_class)
    Captain::Tools.send(:remove_const, class_name) if Captain::Tools.const_defined?(class_name, false)
    Captain::Tools.const_set(class_name, tool_class)
  end
end
