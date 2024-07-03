class Platform::Api::V1::AgentBotsController < PlatformController
  before_action :set_resource, except: [:index, :create]
  before_action :validate_platform_app_permissible, except: [:index, :create]

  def index
    @resources = @platform_app.platform_app_permissibles.where(permissible_type: 'AgentBot').all
  end

  def show; end

  def create
    @resource = AgentBot.new(agent_bot_params.except(:avatar_url))
    @resource.save!
    process_avatar_from_url
    @platform_app.platform_app_permissibles.find_or_create_by(permissible: @resource)
  end

  def update
    @resource.update!(agent_bot_params.except(:avatar_url))
    process_avatar_from_url
  end

  def destroy
    @resource.destroy!
    head :ok
  end

  def avatar
    @resource.avatar.purge if @resource.avatar.attached?
    @resource
  end

  private

  def set_resource
    @resource = AgentBot.find(params[:id])
  end

  def agent_bot_params
    params.permit(:name, :description, :account_id, :outgoing_url, :avatar, :avatar_url)
  end

  def process_avatar_from_url
    ::Avatar::AvatarFromUrlJob.perform_later(@resource, params[:avatar_url]) if params[:avatar_url].present?
  end
end
