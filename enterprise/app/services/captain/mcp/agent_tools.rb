# Builds the MCP tools of an assistant for a run. A tool is offered only while its live definition matches the
# approved digest, so a server cannot change what Captain sees or sends without an admin approving the change.
# Each server is listed once per instance, however many agents ask for its tools.
class Captain::Mcp::AgentTools
  # Isolated namespace for the generated tool classes, as Concerns::Toolable does for custom tools
  module Generated; end

  def self.build(assistant, server, mcp_tool, connection, base_class:)
    tool_name = mcp_tool.captain_name
    tool_description = mcp_tool.description.to_s
    schema = model_schema(mcp_tool, base_class)

    tool_class = Class.new(base_class) do
      description tool_description
      parameters schema
      define_method(:name) { tool_name }
    end
    # Class#name must not be nil, or the LLM request gets an empty function name
    class_name = tool_name.gsub(/[^a-zA-Z0-9]/, '_').camelize
    Generated.send(:remove_const, class_name) if Generated.const_defined?(class_name, false)
    Generated.const_set(class_name, tool_class)

    tool_class.new(assistant, server, mcp_tool, connection)
  end

  # Fixed parameters are always hidden. A verified parameter is hidden unless the user is an admin or an agent.
  def self.model_schema(mcp_tool, base_class)
    hidden = mcp_tool.param_sources.filter_map do |param_name, source|
      param_name if source['source'] == Captain::McpTool::PARAM_SOURCE_FIXED || !base_class.model_fills_verified_values?
    end
    schema = mcp_tool.input_schema.deep_dup
    schema['properties'] = (schema['properties'] || {}).except(*hidden)
    schema['required'] = Array(schema['required']) - hidden
    schema
  end
  private_class_method :model_schema

  def initialize(assistant)
    @assistant = assistant
    @live_digests = {}
    @connections = {}
  end

  def tools(base_class: Captain::Tools::PublicMcpTool)
    @assistant.mcp_servers.enabled.flat_map do |server|
      matching_tools(server).map { |mcp_tool| self.class.build(@assistant, server, mcp_tool, @connections[server.id], base_class: base_class) }
    end
  end

  def tool(name, base_class: Captain::Tools::PublicMcpTool)
    tools(base_class: base_class).find { |agent_tool| agent_tool.name == name }
  end

  private

  def matching_tools(server)
    mcp_tools = server.available_tools.to_a
    return [] if mcp_tools.empty?

    live = live_digests(server)
    mcp_tools.select { |mcp_tool| live[mcp_tool.name] == mcp_tool.approved_digest }
  rescue *Captain::Mcp::Connection::ERRORS => e
    Rails.logger.warn("Captain MCP server #{server.id} skipped: #{e.class} - #{e.message}")
    []
  end

  def live_digests(server)
    @live_digests[server.id] ||= begin
      connection = @connections[server.id] = Captain::Mcp::Connection.new(server)
      definitions = connection.track_status { connection.tool_definitions }
      definitions.to_h { |definition| [definition['name'], Captain::McpTool.definition_digest(definition)] }
    end
  end
end
