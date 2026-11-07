# The MCP tools Captain can use in one run. A tool is usable only while its live definition matches the approved one,
# so a server cannot change what Captain sees or sends without an admin approving the change.
# Each server is listed once per instance, and a server that cannot be listed is skipped for the rest of the run.
# Everything a run decides about MCP tools reads this list, so the agents, the scenario prompts and the email
# verification check agree on which tools exist.
class Captain::Mcp::AgentTools
  # Isolated namespace for the generated tool classes, as Concerns::Toolable does for custom tools
  module Generated; end

  # An approved tool that matches its live definition, with the connection that listed it
  Usable = Struct.new(:mcp_tool, :connection)

  def self.build(assistant, mcp_tool, connection, base_class:)
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

    tool_class.new(assistant, mcp_tool, connection)
  end

  # A parameter the customer does not prove, such as a fixed value, is always hidden.
  # A proven parameter is hidden unless the user is an admin or an agent.
  def self.model_schema(mcp_tool, base_class)
    hidden = mcp_tool.param_sources.filter_map do |param_name, entry|
      param_name if !Captain::ParamSources.proven?(entry) || !base_class.model_fills_verified_values?
    end
    schema = mcp_tool.input_schema.deep_dup
    schema['properties'] = (schema['properties'] || {}).except(*hidden)
    schema['required'] = Array(schema['required']) - hidden
    schema
  end
  private_class_method :model_schema

  def initialize(assistant)
    @assistant = assistant
  end

  def tools
    usable.map { |entry| build(entry) }
  end

  # The tool with this Captain name, or nil when it is not usable in this run
  def tool(captain_name)
    entry = usable.find { |candidate| candidate.mcp_tool.captain_name == captain_name }
    entry && build(entry)
  end

  def usable?(captain_name)
    usable.any? { |entry| entry.mcp_tool.captain_name == captain_name }
  end

  def requires_verified_customer?
    usable.any? { |entry| entry.mcp_tool.requires_verified_customer? }
  end

  private

  def build(entry)
    self.class.build(@assistant, entry.mcp_tool, entry.connection, base_class: Captain::Tools::PublicMcpTool)
  end

  def usable
    @usable ||= Captain::McpServer.usable_for(@assistant).flat_map { |server| usable_on(server) }
  end

  def usable_on(server)
    return [] if server.available_tools.empty?

    connection = Captain::Mcp::Connection.new(server)
    server.record_live_tools(connection.track_status { connection.tool_definitions })
    server.available_tools.select(&:review_current?).map { |mcp_tool| Usable.new(mcp_tool, connection) }
  rescue *Captain::Mcp::Connection::ERRORS => e
    Rails.logger.warn("Captain MCP server #{server.id} skipped: #{e.class} - #{e.message}")
    []
  end
end
