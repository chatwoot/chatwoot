class Api::V1::Accounts::Captain::Assistants::McpServersController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_captain_mcp_feature
  before_action :set_assistant
  before_action -> { check_authorization(@assistant) }
  before_action :set_assistant_mcp_server, only: [:update, :destroy]

  def index
    @assistant_mcp_servers = @assistant.assistant_mcp_servers.includes(:mcp_server)
  end

  def create
    validate_mcp_server_account!
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

  def check_captain_mcp_feature
    return if Current.account.feature_enabled?('captain_mcp')

    render json: { error: I18n.t('errors.captain.mcp_not_enabled') }, status: :forbidden
  end

  def set_assistant
    @assistant = Current.account.captain_assistants.find(params[:assistant_id])
  end

  def set_assistant_mcp_server
    @assistant_mcp_server = @assistant.assistant_mcp_servers.find(params[:id])
  end

  def validate_mcp_server_account!
    server_id = params.dig(:assistant_mcp_server, :captain_mcp_server_id)
    Current.account.captain_mcp_servers.find(server_id)
  end

  def assistant_mcp_server_params
    params.require(:assistant_mcp_server).permit(
      :captain_mcp_server_id,
      :enabled,
      tool_filters: { include: [], exclude: [] }
    )
  end
end
