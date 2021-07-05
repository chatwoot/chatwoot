class Platform::Api::V1::AgentBotsController < PlatformController
  before_action :set_resource, except: [:index, :create]
  before_action :validate_platform_app_permissible, except: [:index, :create]

  def index
    @resources = @platform_app.platform_app_permissibles.where(permissible_type: 'AgentBot').all
  end

  def create
    @resource = AgentBot.new(agent_bot_params)
    @resource.save!
    @platform_app.platform_app_permissibles.find_or_create_by(permissible: @resource)
  end

  def show; end

  def update
    @resource.update!(agent_bot_params)
  end

  def destroy
    @resource.destroy!
    head :ok
  end

  private

  def set_resource
    @resource = AgentBot.find(params[:id])
  end

  def agent_bot_params
    params.permit(:name, :description, :account_id, :outgoing_url)
  end
end
