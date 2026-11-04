class Api::V1::Accounts::Captain::McpServersController < Api::V1::Accounts::BaseController
  before_action :ensure_mcp_servers_enabled
  before_action -> { check_authorization(Captain::McpServer) }
  before_action :set_mcp_server, only: [:show, :update, :destroy, :live_tools, :authorization_url]

  # A failing or unreachable MCP server is the admin's input to fix, not a Chatwoot error
  rescue_from(*Captain::Mcp::Connection::ERRORS) { |error| render_could_not_create_error(error.message) }

  def index
    @mcp_servers = assistant_mcp_servers.includes(:tools).order(id: :desc)
  end

  def show; end

  def discover
    @result = Captain::Mcp::DiscoveryService.new(url: params.require(:url), token: params[:token].presence,
                                                 auth_header: params[:auth_header].presence).perform
  rescue RubyLLM::UnauthorizedError
    render_could_not_create_error(I18n.t('captain.mcp_server.token_rejected'))
  rescue Captain::Mcp::DiscoveryService::InvalidUrlError => e
    render_could_not_create_error(e.message)
  end

  def create
    @mcp_server = assistant_mcp_servers.create!(server_params.merge(account: Current.account))
  end

  def update
    Captain::Mcp::ServerUpdateService.new(@mcp_server, update_params, params[:mcp_server][:tools]).perform
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

  # The API never returns the token, so an edit without a new token keeps the stored one
  def update_params
    attributes = server_params.except(:url, :auth_type)
    attributes[:auth_config].to_h['token'].blank? ? attributes.except(:auth_config) : attributes
  end
end
