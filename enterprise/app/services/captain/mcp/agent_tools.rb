# The MCP tools of one run. A tool is usable only while its live definition matches the approved one, so a server
# cannot change what Captain sees or sends without an admin approving the change. Every enabled tool is offered: one
# that is not usable answers that it is unavailable and never calls its server. A scenario that names a tool therefore
# always matches the tools its agent has.
# Each server is listed once per instance, and a server that cannot be listed makes its tools unavailable for the run.
class Captain::Mcp::AgentTools
  # Isolated namespace for the generated tool classes, as Concerns::Toolable does for custom tools
  module Generated; end

  # An approved tool, with the connection that listed it when it matches its live definition, or nil when it does not
  Entry = Struct.new(:mcp_tool, :connection) do
    def usable?
      connection.present?
    end
  end

  def self.build(assistant, mcp_tool, connection, base_class:)
    tool_name = mcp_tool.captain_name
    tool_description = mcp_tool.description.to_s
    schema = model_schema(mcp_tool, base_class)

    tool_class = Class.new(base_class) do
      description tool_description
      parameters schema
      define_method(:name) { tool_name }
    end
    Captain::Tools::BasePublicTool.register_generated(Generated, tool_name.gsub(/[^a-zA-Z0-9]/, '_').camelize, tool_class)

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
    entries.map { |entry| build(entry) }
  end

  # The tool with this Captain name, or nil when the assistant has no such enabled tool
  def tool(captain_name)
    entry = entries.find { |candidate| candidate.mcp_tool.captain_name == captain_name }
    entry && build(entry)
  end

  # An unavailable tool never runs, so it never needs a verified customer
  def requires_verified_customer?
    entries.any? { |entry| entry.usable? && entry.mcp_tool.requires_verified_customer? }
  end

  private

  def build(entry)
    base_class = entry.usable? ? Captain::Tools::PublicMcpTool : Captain::Tools::UnavailableMcpTool
    self.class.build(@assistant, entry.mcp_tool, entry.connection, base_class: base_class)
  end

  def entries
    @entries ||= Captain::McpServer.enabled_for(@assistant).flat_map { |server| entries_on(server) }
  end

  def entries_on(server)
    return [] if server.available_tools.empty?

    connection = Captain::Mcp::Connection.new(server)
    server.record_live_tools(connection.recent_tool_definitions)
    server.available_tools.map { |mcp_tool| Entry.new(mcp_tool, mcp_tool.review_current? ? connection : nil) }
  rescue *Captain::Mcp::Connection::ERRORS => e
    Rails.logger.warn("Captain MCP server #{server.id} could not be listed: #{e.class} - #{e.message}")
    server.available_tools.map { |mcp_tool| Entry.new(mcp_tool, nil) }
  end
end
