class Api::V1::Accounts::Captain::McpServersController < Api::V1::Accounts::BaseController
  RESULTS_PER_PAGE = 15

  before_action :current_account
  before_action -> { check_authorization(Captain::McpServer) }
  before_action :set_mcp_server, only: [:show, :update, :destroy, :connect, :disconnect, :refresh]

  def index
    @mcp_servers = account_mcp_servers.enabled.order(created_at: :desc).page(params[:page]).per(RESULTS_PER_PAGE)
  end

  def show; end

  def create
    @mcp_server = account_mcp_servers.create!(mcp_server_params)
  end

  def update
    @mcp_server.update!(mcp_server_params)
  end

  def destroy
    @mcp_server.destroy
    head :no_content
  end

  def connect
    discovery_service = Captain::Mcp::DiscoveryService.new(@mcp_server)
    discovery_service.connect_and_discover
    render json: { status: 'connected', tools_count: @mcp_server.cached_tools.size }
  rescue Captain::Mcp::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def disconnect
    Captain::Mcp::ClientService.new(@mcp_server).disconnect
    render json: { status: 'disconnected' }
  end

  def refresh
    discovery_service = Captain::Mcp::DiscoveryService.new(@mcp_server)
    discovery_service.refresh_tools
    render :show
  rescue Captain::Mcp::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_mcp_server
    @mcp_server = account_mcp_servers.find(params[:id])
  end

  def account_mcp_servers
    @account_mcp_servers ||= Current.account.captain_mcp_servers
  end

  def mcp_server_params
    params.require(:mcp_server).permit(
      :name,
      :description,
      :url,
      :auth_type,
      :enabled,
      auth_config: {}
    )
  end
end
