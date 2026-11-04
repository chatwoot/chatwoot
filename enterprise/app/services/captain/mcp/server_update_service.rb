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

  # A new token is not saved yet, so a listing that uses it says nothing about the saved credentials
  def fetch_live_definitions
    connection = Captain::Mcp::Connection.new(@server)
    definitions = @server.will_save_change_to_auth_config? ? connection.tool_definitions : connection.track_status { connection.tool_definitions }
    definitions.index_by { |definition| definition['name'] }
  end

  # The selections are read as sent instead of through permit, which drops unknown or nested values without an error.
  # The tool model then rejects a wrong value with a reason. Returns the fields of each tool by name.
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

  # JsonSchemaValidator checks settings and cannot name the attribute when the whole value has the wrong type,
  # so the request rejects it here
  def valid_selection?(selection)
    selection.is_a?(Hash) && selection['name'].present? && selection.slice('settings').values.all?(Hash)
  end
end
