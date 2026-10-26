class Api::V1::Accounts::Captain::McpServersController < Api::V1::Accounts::BaseController
  DEFAULT_SELECTION = { 'param_sources' => {}, 'settings' => {}, 'enabled' => true }.freeze
  SELECTION_FIELDS = %w[name param_sources settings enabled].freeze

  before_action :ensure_mcp_servers_enabled
  before_action -> { check_authorization(Captain::McpServer) }
  before_action :set_mcp_server, only: [:show, :update, :destroy, :live_tools, :authorization_url]

  # A failing or unreachable MCP server is the admin's input to fix, not a Chatwoot error
  rescue_from(*Captain::Mcp::Connection::ERRORS) { |error| render_could_not_create_error(error.message) }

  def index
    @mcp_servers = assistant_mcp_servers.order(id: :desc)
  end

  def show; end

  def discover
    @result = Captain::Mcp::DiscoveryService.new(url: params.require(:url), token: params[:token].presence,
                                                 auth_header: params[:auth_header].presence).perform
  rescue RubyLLM::UnauthorizedError
    render_could_not_create_error(I18n.t('captain.mcp_server.token_rejected'))
  # RubyLLM raises ArgumentError for a URL that is not HTTPS
  rescue ArgumentError, URI::InvalidURIError => e
    render_could_not_create_error(e.message)
  end

  def create
    @mcp_server = assistant_mcp_servers.create!(
      server_params.merge(account: Current.account, status: server_params[:auth_type] == 'oauth' ? :needs_sign_in : :active)
    )
  end

  def update
    @mcp_server.assign_attributes(server_params.except(:url, :auth_type))
    @mcp_server.tools = approved_tools if params[:mcp_server].key?(:tools)
    @mcp_server.save!
  end

  def destroy
    @mcp_server.destroy!
    head :no_content
  end

  # The live tools, marked with whether an admin approved each one and whether it changed since
  def live_tools
    @live_tools = connection.track_status { connection.tool_definitions }
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

  # A tool that is already approved keeps its approved definition, so editing its parameters never approves a change
  # the server made. A newly selected tool is pinned to its live definition, which must be read-only.
  def approved_tools
    live_tools = nil
    tool_selections.map do |selection|
      approved = @mcp_server.approved_tool(selection['name'])
      next approved.merge(selection.slice('param_sources', 'settings', 'enabled')) if approved

      live_tools ||= connection.track_status { connection.tool_definitions }.index_by { |tool| tool['name'] }
      definition = live_tools[selection['name']]
      raise ActiveRecord::RecordInvalid, invalid_tool(selection['name'], :missing) unless definition
      raise ActiveRecord::RecordInvalid, invalid_tool(selection['name'], :not_read_only) unless definition['read_only']

      Captain::McpServer.approved_entry(definition, **selection.slice('param_sources', 'settings', 'enabled').symbolize_keys)
    end
  end

  # The model validates every field against a strict schema, so the selections are read as sent instead of through permit,
  # which drops unknown or nested values without an error.
  def tool_selections
    Array(params[:mcp_server][:tools]).map do |selection|
      selection = selection.respond_to?(:to_unsafe_h) ? selection.to_unsafe_h : selection.to_h
      DEFAULT_SELECTION.merge(selection.slice(*SELECTION_FIELDS))
    end
  end

  def invalid_tool(name, reason)
    @mcp_server.errors.add(:tools, I18n.t("captain.mcp_server.tools.#{reason}", tool: name))
    @mcp_server
  end
end
