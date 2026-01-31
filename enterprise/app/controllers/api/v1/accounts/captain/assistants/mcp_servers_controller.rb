class Api::V1::Accounts::Captain::Assistants::McpServersController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :set_assistant
  before_action -> { check_authorization(@assistant) }
  before_action :set_assistant_mcp_server, only: [:update, :destroy]

  def index
    @assistant_mcp_servers = @assistant.assistant_mcp_servers.includes(:mcp_server)
  end

  def create
    @assistant_mcp_server = @assistant.assistant_mcp_servers.create!(assistant_mcp_server_params)
    render :show
  end

  def update
    @assistant_mcp_server.update!(assistant_mcp_server_params)
    render :show
  end

  def destroy
    @assistant_mcp_server.destroy
    head :no_content
  end

  private

  def set_assistant
    @assistant = Current.account.captain_assistants.find(params[:assistant_id])
  end

  def set_assistant_mcp_server
    @assistant_mcp_server = @assistant.assistant_mcp_servers.find(params[:id])
  end

  def assistant_mcp_server_params
    params.require(:assistant_mcp_server).permit(
      :captain_mcp_server_id,
      :enabled,
      tool_filters: {}
    )
  end
end
