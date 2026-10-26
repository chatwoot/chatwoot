class Api::V1::Accounts::Captain::McpServersController < Api::V1::Accounts::BaseController
  SELECTION_FIELDS = %w[param_sources settings enabled].freeze

  before_action :ensure_mcp_servers_enabled
  before_action -> { check_authorization(Captain::McpServer) }
  before_action :set_mcp_server, only: [:show, :update, :destroy, :live_tools, :authorization_url, :approve_tool]

  # A failing or unreachable MCP server is the admin's input to fix, not a Chatwoot error
  rescue_from(*Captain::Mcp::Connection::ERRORS) { |error| render_could_not_create_error(error.message) }

  def index
    @mcp_servers = assistant_mcp_servers.includes(:tools).order(id: :desc)
  end

  def show; end

  def suggestions
    @suggestions = Captain::Mcp::SuggestionsService.new(Current.account).perform
    @connected_urls = assistant_mcp_servers.pluck(:url)
  end

  def discover
    @result = Captain::Mcp::DiscoveryService.new(url: params.require(:url), token: params[:token].presence,
                                                 auth_header: params[:auth_header].presence).perform
  rescue RubyLLM::UnauthorizedError
    render_could_not_create_error(I18n.t('captain.mcp_server.token_rejected'))
  rescue Captain::Mcp::DiscoveryService::InvalidUrlError => e
    render_could_not_create_error(e.message)
  end

  def create
    @mcp_server = assistant_mcp_servers.create!(
      server_params.merge(account: Current.account, status: server_params[:auth_type] == 'oauth' ? :needs_sign_in : :active)
    )
  end

  def update
    Captain::McpServer.transaction do
      @mcp_server.update!(update_params)
      sync_tools(tool_selections) if params[:mcp_server].key?(:tools)
    end
  end

  def destroy
    @mcp_server.destroy!
    head :no_content
  end

  # The live tools, marked with whether an admin approved each one and whether it changed since
  def live_tools
    @live_tools = connection.track_status { connection.tool_definitions }
    @mcp_server.record_tool_changes(@live_tools)
  end

  # Pins an approved tool to its live definition after an admin reviewed the change. Parameter sources stay,
  # so a parameter the server removed must lose its source first, and a new parameter is filled by Captain.
  def approve_tool
    name = params.require(:name)
    live_tools = connection.track_status { connection.tool_definitions }
    definition = live_tools.find { |tool| tool['name'] == name }
    mcp_tool = @mcp_server.tools.find_by(name: name)
    raise ActiveRecord::RecordInvalid, invalid_tool(name, :missing) unless definition && mcp_tool
    raise ActiveRecord::RecordInvalid, invalid_tool(name, :not_read_only) unless definition['read_only']

    mcp_tool.approve(definition)
    mcp_tool.save!
    @mcp_server.record_tool_changes(live_tools)
    render :show
  end

  def authorization_url
    return render_could_not_create_error(I18n.t('captain.mcp_server.not_oauth')) unless @mcp_server.auth_oauth?

    render json: { url: connection.authorization_url }
  end

  private

  def ensure_mcp_servers_enabled
    return if Current.account.feature_enabled?(Captain::McpServer::FEATURE_FLAG)

    render json: { error: I18n.t('captain.mcp_server.disabled') }, status: :forbidden
  end

  def set_mcp_server
    @mcp_server = assistant_mcp_servers.find(params[:id])
  end

  def assistant_mcp_servers
    @assistant_mcp_servers ||= Current.account.captain_assistants.find(params[:assistant_id]).mcp_servers
  end

  def connection
    @connection ||= Captain::Mcp::Connection.new(@mcp_server)
  end

  def server_params
    params.require(:mcp_server).permit(:url, :name, :auth_type, :auth_header, :enabled, auth_config: [:token])
  end

  # The API never returns the token, so an edit without a new token keeps the stored one
  def update_params
    attributes = server_params.except(:url, :auth_type)
    attributes[:auth_config].to_h['token'].blank? ? attributes.except(:auth_config) : attributes
  end

  # Makes the approved tools match the selection. A tool that is already approved keeps its approved definition, so
  # editing its parameters never approves a change the server made, and fields the selection leaves out keep their
  # values. A newly selected tool is pinned to its live definition, which must be read-only.
  def sync_tools(selections)
    approved = @mcp_server.tools.index_by(&:name)
    @mcp_server.tools.where.not(name: selections.keys).delete_all
    live_tools = nil
    selections.each do |name, fields|
      tool = approved[name] || begin
        live_tools ||= connection.track_status { connection.tool_definitions }.index_by { |definition| definition['name'] }
        new_tool(name, live_tools[name])
      end
      tool.update!(fields)
    end
    # The loaded list still holds the deleted tools, and the response renders it
    @mcp_server.tools.reset
  end

  def new_tool(name, definition)
    raise ActiveRecord::RecordInvalid, invalid_tool(name, :missing) unless definition
    raise ActiveRecord::RecordInvalid, invalid_tool(name, :not_read_only) unless definition['read_only']

    @mcp_server.tools.new(account: @mcp_server.account, name: name).tap { |tool| tool.approve(definition) }
  end

  # The tool model validates every field against a strict schema, so the selections are read as sent instead of
  # through permit, which drops unknown or nested values without an error. Returns the fields of each tool by name.
  def tool_selections
    selections = Array(params[:mcp_server][:tools]).map do |selection|
      selection = selection.to_unsafe_h if selection.respond_to?(:to_unsafe_h)
      raise ActiveRecord::RecordInvalid, invalid_tool(nil, :invalid_selection) unless valid_selection?(selection)

      selection
    end
    names = selections.pluck('name')
    raise ActiveRecord::RecordInvalid, invalid_tool(nil, :duplicate) if names.uniq.size != names.size

    selections.to_h { |selection| [selection['name'], selection.slice(*SELECTION_FIELDS)] }
  end

  # JsonSchemaValidator cannot name the attribute when a whole value has the wrong type, so the request rejects it here
  def valid_selection?(selection)
    selection.is_a?(Hash) && selection['name'].present? && selection.slice('param_sources', 'settings').values.all?(Hash)
  end

  def invalid_tool(name, reason)
    @mcp_server.errors.add(:tools, I18n.t("captain.mcp_server.tools.#{reason}", tool: name))
    @mcp_server
  end
end
