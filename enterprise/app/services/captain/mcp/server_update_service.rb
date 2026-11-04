# Saves an admin's edit of an MCP server, with the tool selection when the request sends one.
# The edit is validated before the server is called, so the listing uses a new token and an invalid edit sends no
# request. The listing runs before the transaction, so a failed save cannot undo the status or a refreshed token.
class Captain::Mcp::ServerUpdateService
  SELECTION_FIELDS = %w[param_sources settings enabled].freeze

  # tool_selections is the request's list of tools, or nil to leave the tools as they are
  def initialize(server, attributes, tool_selections)
    @server = server
    @attributes = attributes
    @tool_selections = tool_selections
  end

  def perform
    selections = parse_selections unless @tool_selections.nil?
    @server.assign_attributes(@attributes)
    @server.validate!
    live_definitions = selections && @server.new_tool_names(selections.keys).any? ? fetch_live_definitions : {}

    Captain::McpServer.transaction do
      @server.save!
      @server.sync_tools(selections, live_definitions) if selections
    end
  end

  private

  def fetch_live_definitions
    connection = Captain::Mcp::Connection.new(@server)
    connection.track_status { connection.tool_definitions }.index_by { |definition| definition['name'] }
  end

  # The tool model validates every field against a strict schema, so the selections are read as sent instead of
  # through permit, which drops unknown or nested values without an error. Returns the fields of each tool by name.
  def parse_selections
    selections = Array(@tool_selections).map do |selection|
      selection = selection.to_unsafe_h if selection.respond_to?(:to_unsafe_h)
      @server.invalid_tool!(nil, :invalid_selection) unless valid_selection?(selection)

      selection
    end
    names = selections.pluck('name')
    @server.invalid_tool!(nil, :duplicate) if names.uniq.size != names.size

    selections.to_h { |selection| [selection['name'], selection.slice(*SELECTION_FIELDS)] }
  end

  # JsonSchemaValidator cannot name the attribute when a whole value has the wrong type, so the request rejects it here
  def valid_selection?(selection)
    selection.is_a?(Hash) && selection['name'].present? && selection.slice('param_sources', 'settings').values.all?(Hash)
  end
end
